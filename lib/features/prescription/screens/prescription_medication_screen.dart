import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/common/widgets/custom_shapes/containers/t_container.dart';
import 'package:mindheal/features/prescription/controller/prescription_medication_controller.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/routes/routes.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:mindheal/utils/helpers/helper_functions.dart';

class PatientMedicationsScreen extends StatefulWidget {
  const PatientMedicationsScreen({Key? key}) : super(key: key);

  @override
  State<PatientMedicationsScreen> createState() => _PatientMedicationsScreenState();
}

class _PatientMedicationsScreenState extends State<PatientMedicationsScreen> {

  @override
  Widget build(BuildContext context) {
    // Inject the controller globally using Get.put, but reference locally
    final controller = Get.put(PatientMedicationsController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadMedications,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Get.toNamed(TRoutes.prescriptionReader),
            tooltip: 'Add Prescription',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.prescriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medical_services_outlined, size: 80, color: TColors.softGrey),
                const SizedBox(height: TSizes.md),
                Text(
                  'No active prescriptions found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TColors.darkGrey),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                SizedBox(
                  width: 250,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(TRoutes.prescriptionReader),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Scan New Prescription'),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              // Today's Medications (The most critical section)
              _buildTodaysMedications(controller, isDark),
              const SizedBox(height: TSizes.spaceBtwSections),

              // All Prescriptions
              _buildAllPrescriptions(controller, isDark),
            ],
          ),
        );
      }),
    );
  }

  /// Builds the 'Today's Medications' section with swipeable tiles.
  Widget _buildTodaysMedications(PatientMedicationsController controller, bool isDark) {
    final todaysMeds = controller.getTodaysMedications();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Doses",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (todaysMeds.isNotEmpty)
              Chip(
                label: Text('${todaysMeds.length} Due'),
                backgroundColor: TColors.info.withOpacity(0.1),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: TColors.info),
              ),
          ],
        ),
        const SizedBox(height: TSizes.md),

        if (todaysMeds.isEmpty)
          TContainer(
            padding: const EdgeInsets.all(TSizes.md),
            backgroundColor: TColors.success.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: TColors.success),
                const SizedBox(width: TSizes.sm),
                Text('All clear for today! Great job.', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),

        // List of Doses
        if (todaysMeds.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todaysMeds.length,
            itemBuilder: (_, index) {
              final medication = todaysMeds[index];
              return _buildDismissibleMedicationTile(medication, controller, isDark);
            },
          ),
      ],
    );
  }

  /// Builds a single, dismissible medication tile for the 'Today's Medications' list.
  Widget _buildDismissibleMedicationTile(Medication medication, PatientMedicationsController controller, bool isDark) {
    // Using a composite key for Dismissible stability
    final Key key = Key(medication.name + medication.timings.join());

    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Dismissible(
        key: key,
        direction: DismissDirection.startToEnd,
        background: TContainer(
          radius: TSizes.cardRadiusLg,
          backgroundColor: TColors.success,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: TSizes.defaultSpace),
              child: Row(
                children: [
                  Icon(Icons.check, color: TColors.white),
                  SizedBox(width: TSizes.sm),
                  Text('Mark as Taken', style: TextStyle(color: TColors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        onDismissed: (direction) {
          //controller.markMedicationTaken(medication);
          THelperFunctions.showSnackBar('Dose Taken: ${medication.name}',);
        },
        child: _buildMedicationTileContent(medication, isDark),
      ),
    );
  }

  /// The actual content of the medication tile.
  Widget _buildMedicationTileContent(Medication medication, bool isDark) {
    return TContainer(
      padding: const EdgeInsets.all(TSizes.sm),
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      radius: TSizes.cardRadiusLg,
      showBorder: true,
      borderColor: TColors.grey.withOpacity(0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icon / Indicator
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
            ),
            child: const Icon(Icons.poll_outlined, color: TColors.primary),
          ),
          const SizedBox(width: TSizes.md),

          // 2. Name and Dosage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  medication.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${medication.dosage} | ${medication.frequency}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),

          // 3. Time Chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: medication.timings.map((time) {
              final color = _getTimeChipColor(time);
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Chip(
                  label: Text(time, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color == TColors.warning ? TColors.dark : TColors.white,
                  )),
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.xs, vertical: 0),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds the 'All Prescriptions' section.
  Widget _buildAllPrescriptions(PatientMedicationsController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prescription History',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: TSizes.md),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.prescriptions.length,
          itemBuilder: (_, index) {
            final prescription = controller.prescriptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
              child: Card(
                elevation: 1.0,
                color: isDark ? TColors.darkContainer : TColors.lightContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(TSizes.sm),
                  leading: TContainer(
                    width: 50,
                    height: 50,
                    backgroundColor: _getStatusColor(prescription.status).withOpacity(0.15),
                    radius: TSizes.cardRadiusMd,
                    padding: EdgeInsets.zero,
                    child: Center(
                      child: Icon(
                        _getStatusIcon(prescription.status),
                        color: _getStatusColor(prescription.status),
                        size: 28,
                      ),
                    ),
                  ),
                  title: Text(
                    prescription.doctorName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.formattedDate,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        '${prescription.medications.length} medications',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: TColors.darkGrey),
                  onTap: () => Get.toNamed(
                    TRoutes.prescriptionDetails, // Assuming this is the named route
                    arguments: prescription.id,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Helper Functions (Remained the same, but using TColors for better theme integration) ---

  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return TColors.success;
      case PrescriptionStatus.completed:
        return TColors.info;
      case PrescriptionStatus.expired:
        return TColors.error;
      case PrescriptionStatus.cancelled:
        return TColors.darkGrey;
      case PrescriptionStatus.pendingReview:
        return TColors.warning;
      default:
        return TColors.darkGrey;
    }
  }

  IconData _getStatusIcon(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return Icons.check_circle_outline;
      case PrescriptionStatus.completed:
        return Icons.verified_user_outlined;
      case PrescriptionStatus.expired:
        return Icons.lock_clock_outlined;
      case PrescriptionStatus.cancelled:
        return Icons.cancel_outlined;
      case PrescriptionStatus.pendingReview:
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
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

      if (medicationTime.isBefore(now.subtract(const Duration(minutes: 10)))) {
        // Overdue (passed more than 10 mins ago)
        return TColors.error;
      } else if (medicationTime.difference(now).inMinutes <= 30 && medicationTime.isAfter(now)) {
        // Due soon (within the next 30 minutes)
        return TColors.warning;
      }
    }
    // Default or future dose
    return TColors.primary;
  }
}