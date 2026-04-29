import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:mindheal/utils/constants/colors.dart';

import '../../../utils/constants/enums.dart';
import '../controller/caregiver_controller.dart';

class PatientPrescriptionsScreen extends StatelessWidget {
  PatientPrescriptionsScreen({Key? key}) : super(key: key);

  final CaregiverController caregiverController = Get.find();

  @override
  Widget build(BuildContext context) {
    final patient = caregiverController.selectedPatient;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Patient Prescriptions")),
        body: const Center(
          child: Text("No patient selected."),
        ),
      );
    }

    // Load prescriptions for this patient
    //caregiverController.selectPatient(patient);

    return Scaffold(
      appBar: AppBar(
        title: Text("${patient.fullName}'s Prescriptions"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (caregiverController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (caregiverController.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              caregiverController.errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final prescriptions = caregiverController.getPrescriptionsForPatient(patient.id);

        if (prescriptions.isEmpty) {
          return const Center(
            child: Text("No prescriptions found for this patient."),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            return _buildPrescriptionTile(prescriptions[index]);
          },
        );
      }),
    );
  }

  // -------------------------------------------------------
  // 🔹 Prescriptions Tile (Your Original Widget)
  // -------------------------------------------------------
  Widget _buildPrescriptionTile(PrescriptionModel prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(TSizes.sm),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(prescription.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          ),
          child: Icon(
            _getStatusIcon(prescription.status),
            color: _getStatusColor(prescription.status),
          ),
        ),
        title: Text(
          'Dr. ${prescription.doctorName}',
          style: Get.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prescription.clinicName),
            Text(
              '${prescription.medications.length} meds | Active since ${prescription.formattedDate}',
              style: Get.textTheme.bodySmall?.copyWith(
                color: TColors.darkGrey,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: TColors.darkGrey),
        onTap: () => Get.toNamed(
          '/prescription-details',
          arguments: prescription.id,
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // 🔹 Status Colors
  // -------------------------------------------------------
  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return TColors.success;
      case PrescriptionStatus.completed:
        return TColors.primary;
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

  // -------------------------------------------------------
  // 🔹 Status Icons
  // -------------------------------------------------------
  IconData _getStatusIcon(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.active:
        return Icons.check_circle;
      case PrescriptionStatus.completed:
        return Icons.verified;
      case PrescriptionStatus.expired:
        return Icons.lock_clock;
      case PrescriptionStatus.cancelled:
        return Icons.cancel;
      case PrescriptionStatus.pendingReview:
        return Icons.pending_actions;
      default:
        return Icons.help;
    }
  }
}
