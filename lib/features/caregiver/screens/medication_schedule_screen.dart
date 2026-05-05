import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/authentication/authentication_repository.dart';
import 'package:mindheal/data/services/reminders/medication_dose_model.dart';
import 'package:mindheal/features/caregiver/controller/caregiver_controller.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/routes/routes.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/sizes.dart';

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({Key? key}) : super(key: key);

  @override
  State<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  final CaregiverController controller = Get.put(CaregiverController());
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedTimeFilter = 'All';
  String _selectedPatientFilter = 'All';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Schedule'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
            },
            tooltip: 'Today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Section
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
                controller.listenToDosesForDay(selectedDay);
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
              ),
              eventLoader: _getEventsForDay,
            ),
          ),

          // Filters Section
          _buildFiltersSection(),

          const SizedBox(height: TSizes.sm),

          // Medications List
          Expanded(
            child: _buildMedicationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        children: [
          // Time Filter
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTimeFilter,
                    icon: const Icon(Icons.access_time, size: 20),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Times')),
                      DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                      DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                      DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                      DropdownMenuItem(value: 'Night', child: Text('Night')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFilter = value ?? 'All';
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: TSizes.sm),

          // Patient Filter
          Expanded(
            child: Obx(() => Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPatientFilter,
                    icon: const Icon(Icons.person, size: 20),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Patients')),
                      ...controller.patients.map((patient) =>
                          DropdownMenuItem(
                            value: patient.id,
                            child: Text(
                              patient.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                      ).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPatientFilter = value ?? 'All';
                      });
                    },
                  ),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final doses = _getDosesForSelectedDay();

      if (doses.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medical_services, size: 64, color: Colors.grey),
              SizedBox(height: TSizes.md),
              Text(
                'No medications scheduled',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: TSizes.xs),
              Text(
                'Select another date',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        itemCount: doses.length,
        itemBuilder: (context, index) {
          final dose = doses[index];
          final patient = controller.patients.firstWhereOrNull(
                  (p) => p.id == dose.patientId
          );

          return _buildDoseCard(dose, patient);
        },
      );
    });
  }

  Widget _buildDoseCard(MedicationDoseModel dose, UserModel? patient) {
    final isTaken = dose.status == MedicationDoseStatus.taken;
    final isMissed = dose.status == MedicationDoseStatus.missed;
    final canRemind = dose.status == MedicationDoseStatus.pending ||
        dose.status == MedicationDoseStatus.snoozed ||
        dose.status == MedicationDoseStatus.missed;

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      elevation: 3,
      color: isTaken ? Colors.green.shade50 : isMissed ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        side: BorderSide(
          color: isTaken ? Colors.green.shade200 : isMissed ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: TColors.primary.withOpacity(0.1),
                      child: Icon(Icons.person, color: TColors.primary, size: 20),
                    ),
                    const SizedBox(width: TSizes.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient?.fullName ?? 'Patient', style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text(patient?.formattedPhoneNo ?? '', style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                  decoration: BoxDecoration(
                    color: _getDoseStatusColor(dose.status),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                  ),
                  child: Text(
                    dose.status.name.toUpperCase(),
                    style: Get.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.md),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dose.medicationName, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${dose.dosage} | ${dose.frequency}', style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(_formatDoseTime(dose.scheduledAt)),
                  backgroundColor: _getTimeChipColor(_formatDoseTime(dose.scheduledAt)),
                ),
              ],
            ),
            if (dose.instructions.isNotEmpty) ...[
              const SizedBox(height: TSizes.sm),
              Text('Instructions:', style: Get.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700])),
              Text(dose.instructions, style: Get.textTheme.bodySmall),
            ],
            const SizedBox(height: TSizes.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewPrescriptionDetails(dose.prescriptionId),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('View Prescription'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColors.primary,
                      side: BorderSide(color: TColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                if (canRemind)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.sendDoseReminderToPatient(dose),
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text('Send Reminder'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(String prescriptionId,Medication medication, UserModel? patient) {
    final isTaken = _isMedicationTaken(medication);
    final isMissed = _isMedicationMissed(medication);
    final timeStatus = _getTimeStatus(medication.timings);

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      elevation: 3,
      color: isTaken ? Colors.green.shade50 :
      isMissed ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        side: BorderSide(
          color: isTaken ? Colors.green.shade200 :
          isMissed ? Colors.red.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with patient info and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Patient info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: TColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: TColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: TSizes.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient?.fullName ?? '',
                          style: Get.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          patient?.formattedPhoneNo ?? '',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.sm,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(isTaken, isMissed),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                  ),
                  child: Text(
                    _getStatusText(isTaken, isMissed),
                    style: Get.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.md),

            // Medication details
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        medication.genericName.isNotEmpty
                            ? '(${medication.genericName})'
                            : '',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.sm),

            // Dosage and timing
            Wrap(
              children: [
                _buildDetailChip(
                  icon: Icons.medication,
                  text: medication.dosage,
                ),
                const SizedBox(width: TSizes.sm),
                _buildDetailChip(
                  icon: Icons.access_time,
                  text: medication.frequency,
                ),
                _buildDetailChip(
                  icon: Icons.schedule,
                  text: timeStatus,
                ),
              ],
            ),

            const SizedBox(height: TSizes.sm),

            // Timing details
            if (medication.timings.isNotEmpty) ...[
              Wrap(
                spacing: TSizes.xs,
                children: medication.timings.map((time) {
                  return Chip(
                    label: Text(time),
                    backgroundColor: _getTimeChipColor(time),
                    labelStyle: Get.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: TSizes.sm),
            ],

            // Instructions
            if (medication.instructions?.isNotEmpty == true) ...[
              Text(
                'Instructions:',
                style: Get.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                medication.instructions!,
                style: Get.textTheme.bodySmall,
              ),
              const SizedBox(height: TSizes.sm),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewPrescriptionDetails(prescriptionId),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('View Prescription'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColors.primary,
                      side: BorderSide(color: TColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                if (!isTaken && !isMissed)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsTaken(medication),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Mark Taken'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String text}) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(text),
      backgroundColor: Colors.grey[100],
      labelStyle: Get.textTheme.labelSmall,
    );
  }

  Color _getStatusColor(bool isTaken, bool isMissed) {
    if (isTaken) return Colors.green;
    if (isMissed) return Colors.red;
    return TColors.primary;
  }

  String _getStatusText(bool isTaken, bool isMissed) {
    if (isTaken) return 'TAKEN';
    if (isMissed) return 'MISSED';
    return 'PENDING';
  }

  Color _getTimeChipColor(String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    if (timeParts.length == 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      final medicationTime = DateTime(
          now.year, now.month, now.day, hour, minute
      );

      if (medicationTime.isBefore(now)) {
        return Colors.red;
      } else if (medicationTime.difference(now).inMinutes <= 30) {
        return Colors.orange;
      }
    }
    return Colors.blue;
  }

  String _getTimeStatus(List<String> timings) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (var time in timings) {
      if (time == currentTime) {
        return 'NOW';
      }
    }

    final upcoming = timings.firstWhereOrNull(
            (time) => time.compareTo(currentTime) > 0
    );

    if (upcoming != null) {
      return 'Next: $upcoming';
    }

    return 'Completed';
  }

  List<MedicationDoseModel> _getDosesForSelectedDay() {
    if (_selectedDay == null) return [];

    final selectedStart = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final selectedEnd = selectedStart.add(const Duration(days: 1));
    final allDoses = controller.todayDoses.where((dose) {
      if (dose.scheduledAt.isBefore(selectedStart) || !dose.scheduledAt.isBefore(selectedEnd)) return false;
      if (_selectedPatientFilter != 'All' && dose.patientId != _selectedPatientFilter) return false;
      if (_selectedTimeFilter != 'All' && _categorizeTime(_formatDoseTime(dose.scheduledAt)) != _selectedTimeFilter.toLowerCase()) return false;
      return true;
    }).toList();

    // Sort by time
    allDoses.sort((a, b) {
      return a.scheduledAt.compareTo(b.scheduledAt);
    });

    return allDoses;
  }

  String _categorizeTime(String time) {
    final hour = int.tryParse(time.split(':').first) ?? 0;

    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  bool _isMedicationTaken(Medication medication) {
    // In real app, check from database
    return false;
  }

  bool _isMedicationMissed(Medication medication) {
    if (_selectedDay == null) return false;

    final now = DateTime.now();
    if (!isSameDay(_selectedDay!, now)) return false;

    for (var time in medication.timings) {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        final medicationTime = DateTime(
            now.year, now.month, now.day, hour, minute
        );

        if (medicationTime.isBefore(now)) {
          return true;
        }
      }
    }

    return false;
  }

  List<DateTime> _getEventsForDay(DateTime day) {
    final events = <DateTime>[];

    for (var prescription in controller.prescriptions) {
      for (var medication in prescription.medications) {
        if (medication.startDate.isBefore(day) &&
            (medication.endDate == null || medication.endDate!.isAfter(day))) {
          events.add(day);
          break;
        }
      }
    }

    return events;
  }

  void _markAsTaken(Medication medication) {
    controller.markMedicationTaken(medication.id, DateTime.now());
    Get.snackbar(
      'Success',
      'Medication marked as taken',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _viewPrescriptionDetails(String prescription) {
    // Navigate to prescription details
    Get.toNamed(TRoutes.prescriptionDetails, arguments: prescription);
  }

  Color _getDoseStatusColor(MedicationDoseStatus status) {
    switch (status) {
      case MedicationDoseStatus.taken:
        return Colors.green;
      case MedicationDoseStatus.skipped:
        return Colors.grey;
      case MedicationDoseStatus.snoozed:
        return Colors.orange;
      case MedicationDoseStatus.missed:
        return Colors.red;
      case MedicationDoseStatus.pending:
        return TColors.primary;
    }
  }

  String _formatDoseTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
