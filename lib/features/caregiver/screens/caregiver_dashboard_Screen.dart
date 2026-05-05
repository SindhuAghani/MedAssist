import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/authentication/authentication_repository.dart';
import 'package:mindheal/features/caregiver/screens/patients_tab.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/features/caregiver/controller/caregiver_controller.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';

import 'calendar_tab.dart';
import 'medication_schedule_screen.dart';


class CaregiverDashboardScreen extends StatelessWidget {
  CaregiverDashboardScreen({Key? key}) : super(key: key);

  final CaregiverController controller = Get.put(CaregiverController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          _getAppBarTitle(controller.activeTabIndex),
          style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        )),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: TColors.primary),
            onPressed: controller.refreshData,
            tooltip: 'Refresh Data',
          ),
          // IconButton(
          //   icon: const Icon(Icons.notifications, color: TColors.warning),
          //   onPressed: () => Get.toNamed('/notifications'),
          //   tooltip: 'Notifications',
          // ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: TColors.primary),
            onPressed: () => Get.toNamed('/test-report-analytics'),
            tooltip: 'Test Report Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: TColors.error),
            onPressed: () => AuthenticationRepository.instance.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.patients.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return IndexedStack(
          index: controller.activeTabIndex,
          children: [
            DashboardTab(),
            PatientsTab(),
            CalendarTab(),
          ],
        );
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.activeTabIndex,
        onTap: controller.changeTab,
        selectedItemColor: TColors.primary,
        unselectedItemColor: TColors.darkGrey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      )),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return 'Caregiver Dashboard';
      case 1: return 'My Patients';
      case 2: return 'Medication Calendar';
      default: return 'Caregiver Dashboard';
    }
  }
}

// Dashboard Tab
class DashboardTab extends StatelessWidget {
  DashboardTab({Key? key}) : super(key: key);

  final CaregiverController controller = Get.find<CaregiverController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: TSizes.spaceBtwItems,
        children: [
          // 1. Welcome Card
          _buildWelcomeCard(),

          // 2. Statistics Grid
          _buildStatisticsGrid(),

          // 3. Recent Prescriptions
          _buildRecentPrescriptions(),
        ],
      ),
    );
  }


  Widget _buildWelcomeCard() {
    return Obx(() {
      final selectedPatient = controller.selectedPatient;
      if (selectedPatient == null) return const SizedBox();

      return Column (
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${UserController.instance.user.value.firstName}!',
            style: Get.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: TColors.dark,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Manage care for Patients',
            style: Get.textTheme.titleMedium?.copyWith(
              color: TColors.darkGrey,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatisticsGrid() {
    return Obx(() {
      final selectedPatient = controller.selectedPatient;
      if (selectedPatient == null) return const SizedBox();

      // Retrieve contextual data for the selected patient
      //final activeMedications = controller.getActiveMedicationCountForPatient(selectedPatient.id);
      final totalPatient = controller.totalPatients;
     // final dosesDueToday = controller.getDosesDueTodayCountForPatient(selectedPatient.id);
      final activePrescription = controller.activePrescriptions;
     // final missedDoses = controller.getMissedDosesCountForPatient(selectedPatient.id);
      final pendingAction = controller.pendingActions;
     // final activeRx = controller.getActivePrescriptionCountForPatient(selectedPatient.id);
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: TSizes.md,
        mainAxisSpacing: TSizes.md,
        childAspectRatio: 1.3, // Taller aspect ratio for better look
        children: [
          _buildStatCard(
            title: 'Total Patient',
            value: totalPatient.toString(),
            icon: Icons.assignment_turned_in,
            color: TColors.primary,
            onTap: () => controller.changeTab(2),
          ),
          _buildStatCard(
            title: 'Active Prescription',
            value: activePrescription.toString(),
            icon: Icons.medical_services,
            color: TColors.success,
            onTap: () => Get.to(() => MedicationScheduleScreen()),
          ),
          _buildStatCard(
            title: 'Pending Action',
            value: pendingAction.toString(),
            icon: Icons.access_time_filled,
            color: TColors.warning,
            onTap: () => controller.changeTab(1), // Calendar tab
          ),
          _buildStatCard(
            title: 'Test Reports',
            value: totalPatient.toString(),
            icon: Icons.bar_chart,
            color: Colors.teal,
            onTap: () => Get.toNamed('/test-report-list'),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(TSizes.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: TSizes.sm,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    radius: 20,
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    value,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                title,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: TColors.darkGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildRecentPrescriptions() {
    return Obx(() {
      final selectedPatient = controller.selectedPatient;
      if (selectedPatient == null) return const SizedBox();

      final recentPrescriptions = controller.prescriptions
          .where((p) => p.status == PrescriptionStatus.active)
          .toList();

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Prescriptions',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.md),
              if (recentPrescriptions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(TSizes.md),
                    child: Text('No active prescriptions.', style: Get.textTheme.bodyMedium),
                  ),
                )
              else
                Column(
                  children: recentPrescriptions
                      .map((prescription) => _buildPrescriptionTile(prescription))
                      .toList(),
                ),
            ],
          ),
        ),
      );
    });
  }

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
    }
  }

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
    }
  }
}
