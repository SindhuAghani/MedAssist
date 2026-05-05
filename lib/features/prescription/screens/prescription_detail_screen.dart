import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/features/prescription/controller/prescription_detail_controller.dart';
import 'package:mindheal/features/prescription/controller/prescription_reader_controller.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/features/prescription/screens/precription_edit_screen.dart';
import 'package:mindheal/routes/routes.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:mindheal/utils/helpers/helper_functions.dart';

import '../../../common/widgets/custom_shapes/containers/t_container.dart';

class PrescriptionDetailsScreen extends StatelessWidget {
  const PrescriptionDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(PrescriptionDetailsController());
    final prescriptionId = Get.arguments as String?;
    final isDark = THelperFunctions.isDarkMode(context);

    if (prescriptionId != null) {
      controller.loadPrescriptionDetails(prescriptionId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, controller),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Prescription'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Prescription'),
                ),
              ),
            ],
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
                const Icon(Icons.error, size: 64, color: Colors.grey),
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Prescription Header (Doctor, Status, Validity)
              _buildPrescriptionHeader(controller,isDark),
              const SizedBox(height: TSizes.spaceBtwSections),

              // 2. Medications List
              _buildMedicationsSection(controller,isDark),
              const SizedBox(height: TSizes.spaceBtwSections),

              // 3. Simplified Explanation (High Priority)
              _buildSimplifiedTextSection(controller),
              const SizedBox(height: TSizes.spaceBtwSections),

              // 4. Extracted Text (Secondary Detail)
              _buildExtractedTextSection(controller),
              const SizedBox(height: TSizes.spaceBtwSections),

              // 5. Prescription Image
              if (controller.prescription?.imageUrl != null)
                _buildPrescriptionImage(controller),
            ],
          ),
        );
      }),
      // Bottom Bar for Quick Actions
      bottomNavigationBar: Obx(() {
        if (controller.prescription == null) return const SizedBox();
        return _buildBottomActions(controller, isDark);
      }),
    );
  }

  /// -------------------------------------------------------------------
  /// WIDGET BUILDERS
  /// -------------------------------------------------------------------

  /// Builds the main header showing Doctor, Status, and Validity timeline.
  Widget _buildPrescriptionHeader(PrescriptionDetailsController controller,isDark) {
    final prescription = controller.prescription!;

    return TContainer(
      padding: const EdgeInsets.all(TSizes.md),
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: TColors.primary.withOpacity(0.1),
                child: const Icon(
                  Icons.local_hospital,
                  size: 24,
                  color: TColors.primary,
                ),
              ),
              const SizedBox(width: TSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.doctorName,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      prescription.clinicName,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              TContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: TSizes.xs,
                ),
                backgroundColor: _getStatusColor(prescription.status),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                child: Text(
                  prescription.status.name.toUpperCase(),
                  style: Get.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: TSizes.md),
          const Divider(),
          const SizedBox(height: TSizes.md),

          // Validity Timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateInfo(
                title: 'Date Prescribed',
                date: prescription.formattedDate,
                color: Colors.blue,
              ),
              _buildDateInfo(
                title: 'Valid Until',
                date: prescription.formattedValidUntil,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),

          // Progress Indicator
          if (prescription.remainingDays >= 0)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _calculateProgress(prescription),
                  backgroundColor: TColors.softGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    prescription.remainingDays > 7
                        ? Colors.green
                        : prescription.remainingDays > 3
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  '${prescription.remainingDays} days remaining',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Builds a small card for a specific date in the header.
  Widget _buildDateInfo({
    required String title,
    required String date,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Get.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: TSizes.xs),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: color.withOpacity(0.7)),
            const SizedBox(width: TSizes.xs),
            Text(
              date,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: TColors.darkerGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the section for the list of medications.
  Widget _buildMedicationsSection(PrescriptionDetailsController controller,bool isDark) {
    final prescription = controller.prescription!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medication_liquid, color: TColors.primary),
            const SizedBox(width: TSizes.sm),
            Text(
              'Medications',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Chip(
              label: Text('${prescription.medications.length} meds'),
              backgroundColor: isDark ? TColors.darkerGrey :  TColors.softGrey,
            ),
          ],
        ),
        const SizedBox(height: TSizes.md),

        // Medications List
        ...prescription.medications.asMap().entries.map((entry) {
          final index = entry.key;
          final medication = entry.value;
          return _buildMedicationCard(medication, index + 1);
        }).toList(),
      ],
    );
  }

  /// Builds an individual medication card with enhanced readability.
  Widget _buildMedicationCard(Medication medication, int index) {
    final cardColor = _getMedicationStatusColor(medication);
    final isDark = cardColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700];

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Name, Generic Name, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (medication.genericName.isNotEmpty)
                        Text(
                          medication.genericName,
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildMedicationStatusBadge(medication),
              ],
            ),
            const SizedBox(height: TSizes.md),
            const Divider(color: Colors.white30),
            const SizedBox(height: TSizes.md),

            // Row 2: Instructions and Timings
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                if (medication.instructions?.isNotEmpty == true)
                  _buildMedicationDetailRow(
                    icon: Icons.notes,
                    label: 'Dose/Instructions',
                    value: medication.instructions!,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor!,
                  ),
                if (medication.instructions?.isNotEmpty == true)
                  const SizedBox(height: TSizes.md),

                // Timings/Frequency
                if (medication.timings.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequency/Timings:',
                        style: Get.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: TSizes.xs),
                      Wrap(
                        spacing: TSizes.xs,
                        runSpacing: TSizes.xs,
                        children: medication.timings.map((time) => Chip(
                          label: Text(
                            time,
                            style: Get.textTheme.labelSmall?.copyWith(
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                          backgroundColor: isDark ? Colors.white : Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
                        )).toList(),
                      ),
                    ],
                  ),

                // With Food Indicator
                if (medication.withFood)
                  Padding(
                    padding: const EdgeInsets.only(top: TSizes.md),
                    child: TContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.sm,
                        vertical: TSizes.xs,
                      ),
                      backgroundColor: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant, size: 14, color: textColor),
                          const SizedBox(width: TSizes.xs),
                          Text(
                            'Take with food',
                            style: Get.textTheme.labelSmall?.copyWith(
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for building details rows inside the medication card
  Widget _buildMedicationDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: secondaryTextColor),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Get.textTheme.labelSmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              Text(
                value,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildMedicationStatusBadge(Medication medication) {
    // Logic remains the same
    final now = DateTime.now();
    final isActive = medication.startDate.isBefore(now) &&
        (medication.endDate == null || medication.endDate!.isAfter(now));
    final isCompleted =
        medication.endDate != null && medication.endDate!.isBefore(now);

    Color color;
    String text;

    if (isCompleted) {
      color = Colors.green.shade800;
      text = 'COMPLETED';
    } else if (isActive) {
      color = Colors.blue.shade800;
      text = 'ACTIVE';
    } else {
      color = Colors.orange.shade800;
      text = 'UPCOMING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.sm,
        vertical: TSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
      ),
      child: Text(
        text,
        style: Get.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the section for the original extracted text.
  Widget _buildExtractedTextSection(PrescriptionDetailsController controller) {
    final prescription = controller.prescription!;

    if (prescription.extractedText?.isEmpty ?? true) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.document_scanner, color: Colors.blue),
            const SizedBox(width: TSizes.sm),
            Text(
              'Original Prescription Text (OCR)',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.md),
        TContainer(
          padding: const EdgeInsets.all(TSizes.md),
          backgroundColor: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
          child: SelectableText(
            prescription.extractedText!,
            style: Get.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Builds the section for the simplified AI explanation.
  Widget _buildSimplifiedTextSection(PrescriptionDetailsController controller) {
    final prescription = controller.prescription!;

    if (prescription.simplifiedText?.isEmpty ?? true) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.health_and_safety, color: TColors.success),
            const SizedBox(width: TSizes.sm),
            Text(
              'Simplified Explanation',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.md),
        TContainer(
          padding: const EdgeInsets.all(TSizes.md),
          backgroundColor: TColors.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          border: Border.all(color: TColors.success.withOpacity(0.2)),
          child: SelectableText(
            prescription.simplifiedText!,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: TColors.success,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the section for the original image.
  Widget _buildPrescriptionImage(PrescriptionDetailsController controller) {
    final prescription = controller.prescription!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, color: Colors.purple),
            const SizedBox(width: TSizes.sm),
            Text(
              'Prescription Image',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () => _viewFullscreenImage(prescription.imageUrl!),
              tooltip: 'View Fullscreen',
            ),
          ],
        ),
        const SizedBox(height: TSizes.md),
        GestureDetector(
          onTap: () => _viewFullscreenImage(prescription.imageUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            child: Image.network(
              prescription.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.grey),
                        SizedBox(height: TSizes.sm),
                        Text('Failed to load image'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the bottom fixed action bar.
  Widget _buildBottomActions(PrescriptionDetailsController controller,bool isDark) {
    final prescription = controller.prescription!;
    return TContainer(
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.defaultSpace,
        vertical: TSizes.md,
      ),
      showShadow: true,
      child: Row(
        children: [
          // Expanded(
          //   child: OutlinedButton.icon(
          //     onPressed: () => _setReminders(prescription),
          //     icon: const Icon(Icons.alarm),
          //     label: const Text('Set Reminders'),
          //     style: OutlinedButton.styleFrom(
          //       padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          //       foregroundColor: TColors.darkGrey,
          //     ),
          //   ),
          // ),
          // const SizedBox(width: TSizes.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _viewMedicationSchedule(controller),
              icon: const Icon(Icons.schedule, color: TColors.white),
              label: const Text('View Schedule'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                backgroundColor: TColors.primary,
                foregroundColor: TColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------
  /// HELPER METHODS (Mostly unchanged, but moved to the bottom)
  /// -------------------------------------------------------------------

  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return TColors.success;
      case PrescriptionStatus.completed:
        return Colors.blue;
      case PrescriptionStatus.expired:
        return TColors.error;
      case PrescriptionStatus.cancelled:
        return TColors.darkGrey;
      case PrescriptionStatus.pendingReview:
        return TColors.warning;
    }
  }

  Color _getMedicationStatusColor(Medication medication) {
    final now = DateTime.now();
    final isActive = medication.startDate.isBefore(now) &&
        (medication.endDate == null || medication.endDate!.isAfter(now));
    final isCompleted =
        medication.endDate != null && medication.endDate!.isBefore(now);

    if (isCompleted) {
      return TColors.success;
    } else if (isActive) {
      return TColors.info; // Using a slightly different blue for active meds
    } else {
      return TColors.warning;
    }
  }

  double _calculateProgress(PrescriptionModel prescription) {
    if (prescription.validUntil == null) return 1.0;

    final totalDays =
        prescription.validUntil!.difference(prescription.datePrescribed).inDays;
    final daysPassed =
        DateTime.now().difference(prescription.datePrescribed).inDays;

    if (totalDays <= 0) return 1.0;

    return daysPassed / totalDays;
  }

  /// -------------------------------------------------------------------
  /// ACTION HANDLERS (Unchanged functionality)
  /// -------------------------------------------------------------------

  void _handleMenuAction(
      String value, PrescriptionDetailsController controller) {
    switch (value) {
      case 'edit':
        _editPrescription(controller);
        break;
      case 'delete':
        _deletePrescription(controller);
        break;
      case 'download':
        _downloadPrescription(controller.prescription!);
        break;
      case 'assign_caregiver':
        _assignCaregiver(controller);
        break;
    }
  }

  void _editPrescription(PrescriptionDetailsController controller) {
    navigateToEditPrescription(controller.prescription!);
  }

  void _deletePrescription(PrescriptionDetailsController controller) {
    Get.defaultDialog(
      title: 'Delete Prescription',
      middleText:
      'Are you sure you want to delete this prescription? This action cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        try {
          await controller.deletePrescription();
          Get.back(); // Close dialog
          Get.back(); // Navigate back to the previous screen (list)
          Get.snackbar(
            'Success',
            'Prescription deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: TColors.success,
            colorText: TColors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Error',
            'Failed to delete prescription: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: TColors.error,
            colorText: TColors.white,
          );
        }
      },
    );
  }

  void navigateToEditPrescription(PrescriptionModel prescription) {
    final controller = Get.put(PrescriptionReaderController());
    controller.loadPrescriptionForEditing(prescription);

    Get.to(
          () => const EditPrescriptionScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _assignCaregiver(PrescriptionDetailsController controller) {
    //Get.toNamed(TRoutes.assignCaregiver, arguments: controller.prescription!.id);
  }

  void _setReminders(PrescriptionModel prescription) {
   // Get.toNamed(TRoutes.setReminders, arguments: prescription.id);
  }

  void _downloadPrescription(PrescriptionModel prescription) {
    Get.snackbar(
      'Coming Soon',
      'Download prescription feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _viewMedicationSchedule(PrescriptionDetailsController controller) {
    final prescription = controller.prescription;
    if (prescription != null) {
      Get.toNamed(TRoutes.medicationSchedule, arguments: prescription.id);
    }
  }

  void _viewFullscreenImage(String imageUrl) {
    Get.dialog(
      Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}