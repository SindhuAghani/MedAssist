import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/common/widgets/custom_shapes/containers/t_container.dart';
import 'package:mindheal/features/test_reports/controller/test_report_detail_controller.dart';
import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/features/test_reports/models/test_report_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:url_launcher/url_launcher.dart';

class TestReportDetailScreen extends StatefulWidget {
  const TestReportDetailScreen({super.key});

  @override
  State<TestReportDetailScreen> createState() => _TestReportDetailScreenState();
}

class _TestReportDetailScreenState extends State<TestReportDetailScreen> {
  final TestReportDetailController controller = Get.find<TestReportDetailController>();

  @override
  void initState() {
    super.initState();
    final reportId = Get.arguments as String?;
    if (reportId != null) {
      controller.loadReport(reportId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Report Detail')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final report = controller.currentReport.value;
        if (report == null) {
          return const Center(child: Text('No report loaded yet.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(report),
              const SizedBox(height: TSizes.spaceBtwItems),
              _buildSummary(report),
              const SizedBox(height: TSizes.spaceBtwItems),
              _buildMetricsSection(
                title: 'Abnormal Metrics',
                metrics: controller.abnormalMetrics,
                emptyLabel: 'No abnormal values were detected in this report.',
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              _buildMetricsSection(
                title: 'Other Metrics',
                metrics: controller.normalMetrics,
                emptyLabel: 'No normal metrics available to display.',
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              _buildAttachments(report.attachmentUrls),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(TestReportModel report) {
    final statusColor = report.status == TestReportStatus.finalReport ? Colors.green : Colors.orange;

    return TContainer(
      showShadow: true,
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
                      style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
              _buildMetaChip(Icons.calendar_today, report.formattedReportDate),
              _buildMetaChip(Icons.science, '${report.metrics.length} metrics'),
              _buildMetaChip(
                Icons.warning_amber_rounded,
                '${report.abnormalMetrics.length} abnormal',
                color: report.abnormalMetrics.isEmpty ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(TestReportModel report) {
    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Summary', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.md),
          _buildInfoRow('Doctor', report.doctorName.isEmpty ? 'Doctor' : report.doctorName),
          _buildInfoRow('Status', report.status == TestReportStatus.finalReport ? 'Final Report' : 'Draft'),
          if (report.summary.isNotEmpty) _buildInfoRow('Summary', report.summary),
          if (report.notes.isNotEmpty) _buildInfoRow('Notes', report.notes),
        ],
      ),
    );
  }

  Widget _buildMetricsSection({
    required String title,
    required List<TestMetricModel> metrics,
    required String emptyLabel,
  }) {
    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.md),
          if (metrics.isEmpty)
            Text(
              emptyLabel,
              style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
            )
          else
            ...metrics.map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: TSizes.md),
                child: _buildMetricTile(metric),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(TestMetricModel metric) {
    final flagColor = _flagColor(metric.flag);
    final valueLabel = metric.value?.toString() ?? 'N/A';

    return TContainer(
      backgroundColor: Colors.grey.shade50,
      showBorder: true,
      borderColor: Colors.grey.shade200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.metricLabel,
                  style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                label: Text(metric.flag.name.toUpperCase()),
                backgroundColor: flagColor.withValues(alpha: 0.12),
                labelStyle: TextStyle(color: flagColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            '$valueLabel ${metric.unit}'.trim(),
            style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            _referenceLabel(metric),
            style: Get.textTheme.bodySmall?.copyWith(color: TColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(List<String> attachmentUrls) {
    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attachments', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.md),
          if (attachmentUrls.isEmpty)
            Text(
              'No attachments were uploaded with this report.',
              style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
            )
          else
            ...attachmentUrls.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: Text('Attachment ${entry.key + 1}'),
                subtitle: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openAttachment(entry.value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Get.textTheme.labelLarge?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(value, style: Get.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    final chipColor = color ?? TColors.primary;
    return Chip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(label),
      backgroundColor: chipColor.withValues(alpha: 0.08),
      labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w500),
      side: BorderSide.none,
    );
  }

  String _referenceLabel(TestMetricModel metric) {
    if (metric.referenceMin == null || metric.referenceMax == null) {
      return 'Reference range not provided';
    }

    final unitSuffix = metric.unit.isEmpty ? '' : ' ${metric.unit}';
    return 'Reference: ${metric.referenceMin} - ${metric.referenceMax}$unitSuffix';
  }

  Color _flagColor(TestMetricFlag flag) {
    switch (flag) {
      case TestMetricFlag.low:
        return Colors.orange;
      case TestMetricFlag.normal:
        return Colors.green;
      case TestMetricFlag.high:
        return Colors.red;
      case TestMetricFlag.unknown:
        return Colors.blueGrey;
    }
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Get.snackbar(
        'Invalid Link',
        'This attachment URL is not valid.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      Get.snackbar(
        'Unable to Open',
        'Could not open the report attachment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
