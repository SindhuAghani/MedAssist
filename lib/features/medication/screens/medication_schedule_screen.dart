import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/features/medication/controller/medication_schedule_controller.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:mindheal/utils/helpers/helper_functions.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../utils/constants/enums.dart';

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({super.key});

  @override
  State<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  final MedicationScheduleController controller = Get.put(MedicationScheduleController());
  late String prescriptionId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args != null) {
      prescriptionId = args as String;
      controller.loadPrescriptionSchedule(prescriptionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Schedule'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadPrescriptionSchedule(prescriptionId),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => controller.goToToday(),
            tooltip: 'Today',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.prescription == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medical_services, size: 64, color: Colors.grey),
                const SizedBox(height: TSizes.md),
                const Text(
                  'Prescription not found',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: TSizes.sm),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        final prescription = controller.prescription!;

        return Column(
          children: [
            // Prescription Header
            _buildPrescriptionHeader(prescription),

            // Date Selector
            _buildDateSelector(),

            // Medications List
            Expanded(
              child: _buildMedicationsList(prescription),
            ),

            // Statistics
            _buildStatistics(),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.prescription == null) return const SizedBox();

        return FloatingActionButton.extended(
          onPressed: () => _markAllAsTaken(),
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark All as Taken'),
          backgroundColor: TColors.primary,
        );
      }),
    );
  }

  Widget _buildPrescriptionHeader(PrescriptionModel prescription) {
    return Card(
      margin: const EdgeInsets.all(TSizes.defaultSpace),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: TColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.doctorName,
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        prescription.clinicName,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(prescription.status.name.toUpperCase()),
                  backgroundColor: _getStatusColor(prescription.status),
                  labelStyle: Get.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.md),
            Text(
              'Medication Schedule',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: TColors.primary,
              ),
            ),
            const SizedBox(height: TSizes.xs),
            Text(
              '${prescription.medications.length} medications prescribed',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.previousDay,
            tooltip: 'Previous Day',
          ),
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () => _selectDate(),
              child: Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      controller.selectedDayFormatted,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      controller.selectedDayWeekday,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.nextDay,
            tooltip: 'Next Day',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(),
            tooltip: 'Select Date',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList(PrescriptionModel prescription) {
    final medications = controller.getMedicationsForSelectedDay(prescription);

    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 64, color: Colors.grey),
            const SizedBox(height: TSizes.md),
            const Text(
              'No medications scheduled for this date',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: TSizes.xs),
            Text(
              'Try selecting another date',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        final isTaken = controller.isMedicationTaken(medication.id);
        final isMissed = controller.isMedicationMissed(medication);

        return _buildMedicationCard(medication, isTaken, isMissed);
      },
    );
  }

  Widget _buildMedicationCard(Medication medication, bool isTaken, bool isMissed) {
    final timeStatus = _getTimeStatus(medication.timings);
    final now = DateTime.now();
    final isToday = isSameDay(controller.selectedDay, now);

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
            // Medication Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getMedicationColor(medication).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: _getMedicationColor(medication),
                    size: 24,
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
                      if (medication.genericName.isNotEmpty)
                        Text(
                          medication.genericName,
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status Indicator
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTaken ? Colors.green :
                        isMissed ? Colors.red :
                        isToday ? Colors.orange : Colors.blue,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TSizes.xs),
                    Text(
                      isTaken ? 'TAKEN' :
                      isMissed ? 'MISSED' :
                      isToday ? 'TODAY' : 'SCHEDULED',
                      style: Get.textTheme.labelSmall?.copyWith(
                        color: isTaken ? Colors.green :
                        isMissed ? Colors.red :
                        isToday ? Colors.orange : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: TSizes.md),

            // Dosage and Frequency
            Row(
              children: [
                _buildDetailChip(
                  icon: Icons.medication,
                  text: medication.dosage,
                  color: Colors.blue,
                ),
                const SizedBox(width: TSizes.sm),
                _buildDetailChip(
                  icon: Icons.access_time,
                  text: medication.frequency,
                  color: Colors.purple,
                ),
                const SizedBox(width: TSizes.sm),
                _buildDetailChip(
                  icon: Icons.calendar_today,
                  text: medication.duration,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: TSizes.md),

            // Timings
            Text(
              'Timings:',
              style: Get.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.xs),
            Wrap(
              spacing: TSizes.xs,
              children: medication.timings.map((time) {
                final isTimePassed = _isTimePassed(time);
                final isTimeNow = _isTimeNow(time);

                return Chip(
                  label: Text(
                    time,
                    style: Get.textTheme.labelSmall?.copyWith(
                      color: isTimePassed ? Colors.white : Colors.black,
                    ),
                  ),
                  backgroundColor: isTimePassed ? Colors.grey :
                  isTimeNow ? Colors.orange : Colors.blue.shade100,
                  avatar: isTimeNow
                      ? const Icon(Icons.access_time, size: 14, color: Colors.white)
                      : null,
                );
              }).toList(),
            ),

            const SizedBox(height: TSizes.md),

            // Time Status
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: _getTimeStatusColor(timeStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                border: Border.all(
                  color: _getTimeStatusColor(timeStatus).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTimeStatusIcon(timeStatus),
                    color: _getTimeStatusColor(timeStatus),
                    size: 16,
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: Text(
                      timeStatus,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: _getTimeStatusColor(timeStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            if (medication.instructions?.isNotEmpty == true) ...[
              const SizedBox(height: TSizes.md),
              Text(
                'Instructions:',
                style: Get.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                medication.instructions!,
                style: Get.textTheme.bodyMedium,
              ),
            ],

            // With Food Indicator
            if (medication.withFood) ...[
              const SizedBox(height: TSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: TSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant, size: 14, color: Colors.green),
                    const SizedBox(width: TSizes.xs),
                    Text(
                      'Take with food',
                      style: Get.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Side Effects
            if (medication.sideEffects?.isNotEmpty == true) ...[
              const SizedBox(height: TSizes.sm),
              Text(
                'Possible side effects:',
                style: Get.textTheme.labelSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: TSizes.xs,
                children: medication.sideEffects!.map((effect) => Chip(
                  label: Text(
                    effect,
                    style: Get.textTheme.labelSmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  backgroundColor: Colors.red.shade50,
                )).toList(),
              ),
            ],

            const SizedBox(height: TSizes.md),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewMedicationDetails(medication),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TColors.primary,
                      side: BorderSide(color: TColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isTaken ? null : () => _markAsTaken(medication),
                    icon: Icon(
                      isTaken ? Icons.check_circle : Icons.check,
                      size: 16,
                    ),
                    label: Text(isTaken ? 'Already Taken' : 'Mark as Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTaken ? Colors.grey : Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            // Snooze Button (only for upcoming medications)
            if (!isTaken && !isMissed && isToday) ...[
              const SizedBox(height: TSizes.sm),
              OutlinedButton.icon(
                onPressed: () => _snoozeMedication(medication),
                icon: const Icon(Icons.snooze, size: 16),
                label: const Text('Snooze for 30 minutes'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: Get.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.medical_services,
            value: controller.totalMedications,
            label: 'Total',
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.check_circle,
            value: controller.takenMedications,
            label: 'Taken',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.warning,
            value: controller.missedMedications,
            label: 'Missed',
            color: Colors.red,
          ),
          _buildStatItem(
            icon: Icons.access_time,
            value: controller.pendingMedications,
            label: 'Pending',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: TSizes.xs),
        Text(
          value.toString(),
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Get.textTheme.labelSmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active: return Colors.green;
      case PrescriptionStatus.completed: return Colors.blue;
      case PrescriptionStatus.expired: return Colors.red;
      case PrescriptionStatus.cancelled: return Colors.grey;
      case PrescriptionStatus.pendingReview: return Colors.orange;
    }
  }

  Color _getMedicationColor(Medication medication) {
    // Generate consistent color based on medication name
    final hash = medication.name.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getTimeStatus(List<String> timings) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Check if any timing is exactly now
    for (var time in timings) {
      if (time == currentTime) {
        return 'NOW - Take medication immediately';
      }
    }

    // Check for upcoming timings
    final upcoming = timings.where((time) => time.compareTo(currentTime) > 0).toList();
    if (upcoming.isNotEmpty) {
      upcoming.sort();
      return 'Next dose at ${upcoming.first}';
    }

    // All timings passed
    return 'All doses completed for today';
  }

  Color _getTimeStatusColor(String status) {
    if (status.contains('NOW')) return Colors.red;
    if (status.contains('Next')) return Colors.orange;
    return Colors.green;
  }

  IconData _getTimeStatusIcon(String status) {
    if (status.contains('NOW')) return Icons.notifications_active;
    if (status.contains('Next')) return Icons.access_time;
    return Icons.check_circle;
  }

  bool _isTimePassed(String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    if (timeParts.length != 2) return false;

    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    final medicationTime = DateTime(now.year, now.month, now.day, hour, minute);
    return medicationTime.isBefore(now);
  }

  bool _isTimeNow(String time) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return time == currentTime;
  }

  // Action Methods
  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != controller.selectedDay) {
      controller.selectDate(picked);
    }
  }

  void _markAsTaken(Medication medication) {
    controller.markMedicationAsTaken(medication.id);
  }

  void _markAllAsTaken() {
    Get.defaultDialog(
      title: 'Mark All as Taken',
      middleText: 'Are you sure you want to mark all medications as taken for today?',
      textConfirm: 'Yes, Mark All',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.markAllMedicationsAsTaken();
        Get.back();
      },
    );
  }

  void _viewMedicationDetails(Medication medication) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: TSizes.md),
            Text(
              medication.name,
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (medication.genericName.isNotEmpty) ...[
              const SizedBox(height: TSizes.xs),
              Text(
                '(${medication.genericName})',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: TSizes.md),
            _buildDetailRow('Dosage', medication.dosage),
            _buildDetailRow('Frequency', medication.frequency),
            _buildDetailRow('Duration', medication.duration),
            if (medication.instructions?.isNotEmpty == true)
              _buildDetailRow('Instructions', medication.instructions!),
            if (medication.notes?.isNotEmpty == true)
              _buildDetailRow('Notes', medication.notes!),
            const SizedBox(height: TSizes.md),
            Text(
              'Timings:',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.xs),
            Wrap(
              spacing: TSizes.xs,
              children: medication.timings.map((time) => Chip(
                label: Text(time),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              value,
              style: Get.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _snoozeMedication(Medication medication) {
    Get.snackbar(
      'Snoozed',
      'Reminder for ${medication.name} snoozed for 30 minutes',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}