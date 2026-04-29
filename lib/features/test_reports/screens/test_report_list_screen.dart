import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/common/widgets/custom_shapes/containers/t_container.dart';
import 'package:mindheal/features/test_reports/controller/test_report_list_controller.dart';
import 'package:mindheal/features/test_reports/models/test_report_model.dart';
import 'package:mindheal/routes/routes.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';

class TestReportListScreen extends StatelessWidget {
  const TestReportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TestReportListController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.screenTitle)),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () => Get.toNamed(TRoutes.testReportAnalytics),
            tooltip: 'Analytics',
          ),
          Obx(
            () => controller.canCreateReports
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => Get.toNamed(TRoutes.testReportForm),
                    tooltip: 'Create Report',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildMessageState(
            title: 'Unable to Load Reports',
            subtitle: controller.errorMessage.value,
            actionLabel: 'Retry',
            onPressed: controller.refreshReports,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshReports,
          child: ListView(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            children: [
              _buildFilters(controller),
              const SizedBox(height: TSizes.spaceBtwItems),
              if (controller.filteredReports.isEmpty)
                _buildMessageState(
                  title: 'No Test Reports Yet',
                  subtitle: controller.currentUserRole == AppRole.doctor
                      ? 'Create the first structured report to start building charts and patient history.'
                      : 'No reports are available for this account yet.',
                  actionLabel: controller.canCreateReports ? 'Create Report' : null,
                  onPressed: controller.canCreateReports
                      ? () => Get.toNamed(TRoutes.testReportForm)
                      : null,
                )
              else
                ...controller.filteredReports.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: TSizes.md),
                    child: _buildReportCard(controller, report),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilters(TestReportListController controller) {
    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report History',
            style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.md),
          TextField(
            onChanged: controller.updateSearch,
            decoration: const InputDecoration(
              hintText: 'Search by type, patient, lab, or doctor',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          DropdownButtonFormField<TestReportType?>(
            initialValue: controller.selectedReportType.value,
            decoration: const InputDecoration(
              labelText: 'Filter by Report Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: [
              const DropdownMenuItem<TestReportType?>(
                value: null,
                child: Text('All Report Types'),
              ),
              ...TestReportType.values.map(
                (type) => DropdownMenuItem<TestReportType?>(
                  value: type,
                  child: Text(_reportTypeLabel(type)),
                ),
              ),
            ],
            onChanged: controller.filterByType,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(TestReportListController controller, TestReportModel report) {
    final abnormalCount = report.abnormalMetrics.length;
    final patientName = controller.getPatientName(report.patientId);
    final statusColor = report.status == TestReportStatus.finalReport ? Colors.green : Colors.orange;

    return TContainer(
      showShadow: true,
      onTap: () => Get.toNamed(TRoutes.testReportDetail, arguments: report.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reportTypeLabel,
                      style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: TSizes.xs),
                    Text(
                      report.labName.isEmpty ? 'Lab not provided' : report.labName,
                      style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(report.status == TestReportStatus.finalReport ? 'FINAL' : 'DRAFT'),
                backgroundColor: statusColor.withValues(alpha: 0.12),
                labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          Wrap(
            spacing: TSizes.sm,
            runSpacing: TSizes.sm,
            children: [
              _buildInfoChip(Icons.calendar_today, report.formattedReportDate),
              _buildInfoChip(Icons.science_outlined, '${report.metrics.length} metrics'),
              _buildInfoChip(
                Icons.warning_amber_rounded,
                '$abnormalCount abnormal',
                color: abnormalCount > 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          if (controller.currentUserRole != AppRole.patient)
            Text(
              'Patient: $patientName',
              style: Get.textTheme.bodyMedium,
            ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Doctor: ${report.doctorName.isEmpty ? 'Doctor' : report.doctorName}',
            style: Get.textTheme.bodyMedium,
          ),
          if (report.summary.isNotEmpty) ...[
            const SizedBox(height: TSizes.sm),
            Text(
              report.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Get.textTheme.bodySmall?.copyWith(color: TColors.textSecondary),
            ),
          ],
          const SizedBox(height: TSizes.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Open Report',
              style: Get.textTheme.labelLarge?.copyWith(
                color: TColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    final chipColor = color ?? TColors.primary;
    return Chip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(label),
      backgroundColor: chipColor.withValues(alpha: 0.08),
      labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w500),
      side: BorderSide.none,
    );
  }

  Widget _buildMessageState({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: TContainer(
          showShadow: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
              ),
              if (actionLabel != null && onPressed != null) ...[
                const SizedBox(height: TSizes.md),
                ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _reportTypeLabel(TestReportType type) {
    switch (type) {
      case TestReportType.cbc:
        return 'CBC';
      case TestReportType.bloodGlucose:
        return 'Blood Glucose';
      case TestReportType.lipidProfile:
        return 'Lipid Profile';
      case TestReportType.thyroid:
        return 'Thyroid';
      case TestReportType.liverFunction:
        return 'Liver Function';
    }
  }
}
