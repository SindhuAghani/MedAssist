import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/features/caregiver/controller/caregiver_controller.dart';
import 'package:mindheal/features/caregiver/screens/patient_prescription_screen.dart';
import 'package:mindheal/features/caregiver/screens/patient_screen.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';

class PatientsTab extends StatelessWidget {
  PatientsTab({Key? key}) : super(key: key);

  final CaregiverController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.patients.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          // Header with Add Button
          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Patients (${controller.patients.length})',
                  style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => Get.to(AddPatientScreen()),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add Patient'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusLg), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),

          const SizedBox(height: TSizes.md),

          // Patients List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await controller.refreshData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                itemCount: controller.patients.length,
                itemBuilder: (context, index) {
                  final patient = controller.patients[index];
                  final prescriptions = controller.getPrescriptionsForPatient(patient.id);
                  final todayMedications = controller.getTodayMedicationsForPatient(patient.id);

                  return _buildPatientCard(patient, prescriptions, todayMedications);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPatientCard(UserModel patient, List<PrescriptionModel> prescriptions, List<Medication> todayMedications) {
    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.defaultSpace),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusLg)),
      child: InkWell(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        onTap: () {
          controller.selectPatient(patient);
          Get.to(PatientPrescriptionsScreen());
        },
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Header
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: TColors.primary.withOpacity(0.3), width: 2),
                    ),
                    child: patient.profilePicture.isNotEmpty
                        ? CircleAvatar(backgroundImage: NetworkImage(patient.profilePicture))
                        : Center(
                            child: Text(
                              patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : 'P',
                              style: Get.textTheme.headlineSmall?.copyWith(color: TColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),

                  const SizedBox(width: TSizes.md),

                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.fullName, style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          patient.email,
                          style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(patient.formattedPhoneNo, style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),

                  // Status Indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: patient.isProfileActive ? Colors.green : Colors.grey,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.md),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    value: prescriptions.length.toString(),
                    label: 'Prescriptions',
                    icon: Icons.description,
                    color: Colors.blue,
                  ),
                  _buildStatItem(value: todayMedications.length.toString(), label: 'Today', icon: Icons.today, color: Colors.green),
                  _buildStatItem(
                    value: patient.verificationStatus.name,
                    label: 'Status',
                    icon: _getVerificationIcon(patient.verificationStatus),
                    color: _getVerificationColor(patient.verificationStatus),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.md),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.toNamed('/test-report-list'),
                      icon: const Icon(Icons.analytics_outlined, size: 16),
                      label: const Text('Reports'),
                    ),
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _removePatient(patient),
                      icon: const Icon(Icons.remove_circle, size: 16),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label, required IconData icon, required Color color}) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: TSizes.xs),
        Text(
          value,
          style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: Get.textTheme.labelSmall?.copyWith(color: Colors.grey)),
      ],
    );
  }

  IconData _getVerificationIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return Icons.verified;
      case VerificationStatus.pending:
        return Icons.pending;
      case VerificationStatus.submitted:
        return Icons.hourglass_empty;
      case VerificationStatus.underReview:
        return Icons.reviews;
      case VerificationStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getVerificationColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.submitted:
        return Colors.blue;
      case VerificationStatus.underReview:
        return Colors.purple;
      case VerificationStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _removePatient(UserModel patient) {
    Get.defaultDialog(
      title: 'Remove Patient',
      middleText: 'Are you sure you want to remove ${patient.fullName} from your care?',
      textConfirm: 'Yes, Remove',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        await controller.removePatient(patient.id);
      },
    );
  }
}
