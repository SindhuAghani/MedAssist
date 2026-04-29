import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/features/caregiver/controller/caregiver_controller.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:mindheal/utils/helpers/helper_functions.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({Key? key}) : super(key: key);

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final CaregiverController controller = Get.find();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  void _loadEvents() {
    _events = {};

    for (var prescription in controller.prescriptions) {
      for (var medication in prescription.medications) {
        // Create events for each day the medication is active
        final startDate = medication.startDate;
        final endDate = medication.endDate ?? startDate.add(const Duration(days: 30));

        DateTime currentDate = startDate;
        while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
          final eventDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

          // Add event for each timing
          for (var timing in medication.timings) {
            final event = CalendarEvent(
              medication: medication,
              patientId: prescription.patientId,
              timing: timing,
              prescriptionId: prescription.id,
            );

            if (_events[eventDate] != null) {
              _events[eventDate]!.add(event);
            } else {
              _events[eventDate] = [event];
            }
          }

          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar
        Card(
          margin: const EdgeInsets.all(TSizes.defaultSpace),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          ),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarFormat: _calendarFormat,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: TColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: TColors.primary),
              ),
              markersAnchor: 1,
              markersAlignment: Alignment.bottomCenter,
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
          ),
        ),

        // Selected Day Events
        Expanded(
          child: _buildDayEvents(),
        ),
      ],
    );
  }

  Widget _buildDayEvents() {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a date'));
    }

    final dayEvents = _events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];

    if (dayEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey),
            SizedBox(height: TSizes.md),
            Text(
              'No medications scheduled',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        final patient = controller.patients.firstWhereOrNull(
                (p) => p.id == event.patientId
        );

        return _buildEventCard(event, patient);
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event, UserModel? patient) {
    final now = DateTime.now();
    final isToday = isSameDay(_selectedDay, now);
    final timeParts = event.timing.split(':');
    final eventTime = timeParts.length == 2
        ? '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}'
        : event.timing;

    final isPast = isToday &&
        eventTime.compareTo('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}') < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      elevation: 2,
      color: isPast ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        side: BorderSide(
          color: isPast ? Colors.grey.shade300 : _getTimeColor(event.timing),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 60,
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: _getTimeColor(event.timing).withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
              ),
              child: Column(
                children: [
                  Text(
                    eventTime,
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTimeColor(event.timing),
                    ),
                  ),
                  Text(
                    _getTimePeriod(event.timing),
                    style: Get.textTheme.labelSmall?.copyWith(
                      color: _getTimeColor(event.timing),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: TSizes.md),

            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: TSizes.sm),
                      Expanded(
                        child: Text(
                          event.medication.name,
                          style: Get.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: TSizes.xs),

                  Text(
                    '${event.medication.dosage} - ${event.medication.frequency}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: TSizes.xs),

                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: TSizes.xs),
                      Expanded(
                        child: Text(
                          patient?.fullName ?? 'Unknown Patient',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (event.medication.instructions?.isNotEmpty == true) ...[
                    const SizedBox(height: TSizes.xs),
                    Text(
                      event.medication.instructions!,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Status indicator
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  isPast ? 'Due' : 'Upcoming',
                  style: Get.textTheme.labelSmall?.copyWith(
                    color: isPast ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTimeColor(String time) {
    final hour = int.tryParse(time.split(':').first) ?? 0;

    if (hour >= 5 && hour < 12) return Colors.orange; // Morning
    if (hour >= 12 && hour < 17) return Colors.blue; // Afternoon
    if (hour >= 17 && hour < 21) return Colors.purple; // Evening
    return Colors.indigo; // Night
  }

  String _getTimePeriod(String time) {
    final hour = int.tryParse(time.split(':').first) ?? 0;

    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }
}

// Calendar Event Model
class CalendarEvent {
  final Medication medication;
  final String patientId;
  final String timing;
  final String prescriptionId;

  CalendarEvent({
    required this.medication,
    required this.patientId,
    required this.timing,
    required this.prescriptionId,
  });
}