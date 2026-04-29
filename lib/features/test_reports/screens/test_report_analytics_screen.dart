import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/common/widgets/custom_shapes/containers/t_container.dart';
import 'package:mindheal/features/test_reports/controller/test_report_analytics_controller.dart';
import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';

class TestReportAnalyticsScreen extends StatelessWidget {
  const TestReportAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TestReportAnalyticsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Test Report Analytics')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildMessageState(
            title: 'Unable to Load Analytics',
            subtitle: controller.errorMessage.value,
          );
        }

        if (controller.availablePatients.isEmpty) {
          return _buildMessageState(
            title: 'No Patients Available',
            subtitle: 'Analytics will appear here when at least one patient has structured test reports.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilters(controller),
              const SizedBox(height: TSizes.spaceBtwItems),
              if (controller.selectedMetricTrend.isEmpty)
                _buildMessageState(
                  title: 'No Trend Data Yet',
                  subtitle: 'Save at least one structured report for the selected patient and report type to generate charts.',
                )
              else ...[
                _buildSummary(controller),
                const SizedBox(height: TSizes.spaceBtwItems),
                _buildChart(controller),
                const SizedBox(height: TSizes.spaceBtwItems),
                _buildTrendTable(controller),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilters(TestReportAnalyticsController controller) {
    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Filters',
            style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.md),
          if (controller.availablePatients.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: controller.selectedPatientId.value,
              decoration: const InputDecoration(
                labelText: 'Patient',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
              items: controller.availablePatients
                  .map(
                    (patient) => DropdownMenuItem<String>(
                      value: patient.id,
                      child: Text(patient.fullName.isEmpty ? patient.email : patient.fullName),
                    ),
                  )
                  .toList(),
              onChanged: controller.setPatient,
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
          ],
          DropdownButtonFormField<TestReportType>(
            initialValue: controller.selectedReportType.value,
            decoration: const InputDecoration(
              labelText: 'Report Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.science),
            ),
            items: TestReportType.values
                .map(
                  (type) => DropdownMenuItem<TestReportType>(
                    value: type,
                    child: Text(_reportTypeLabel(type)),
                  ),
                )
                .toList(),
            onChanged: controller.setReportType,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          DropdownButtonFormField<String>(
            initialValue: controller.selectedMetricKey.value.isEmpty ? null : controller.selectedMetricKey.value,
            decoration: const InputDecoration(
              labelText: 'Metric',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.show_chart),
            ),
            items: controller.availableMetrics
                .map(
                  (metric) => DropdownMenuItem<String>(
                    value: metric.metricKey,
                    child: Text(metric.metricLabel),
                  ),
                )
                .toList(),
            onChanged: controller.setMetricKey,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(TestReportAnalyticsController controller) {
    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.selectedMetricLabel,
            style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Patient: ${controller.selectedPatientName}',
            style: Get.textTheme.bodyMedium,
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Reports analyzed: ${controller.selectedMetricTrend.length}',
            style: Get.textTheme.bodyMedium,
          ),
          if (controller.selectedMetricUnit.isNotEmpty) ...[
            const SizedBox(height: TSizes.xs),
            Text(
              'Unit: ${controller.selectedMetricUnit}',
              style: Get.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: TSizes.md),
          Text(
            controller.trendSummary,
            style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(TestReportAnalyticsController controller) {
    final trend = controller.selectedMetricTrend;
    final spots = trend.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final minY = trend.map((point) => point.value).reduce((a, b) => a < b ? a : b);
    final maxY = trend.map((point) => point.value).reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.2;

    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Chart',
            style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.md),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: trend.length == 1 ? 1 : (trend.length - 1).toDouble(),
                minY: minY - yPadding,
                maxY: maxY + yPadding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yPadding <= 0 ? 1 : yPadding,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                        final date = trend[index].reportDate;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: TColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: TColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: TColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendTable(TestReportAnalyticsController controller) {
    return TContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Points',
            style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.md),
          ...controller.selectedMetricTrend.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: TSizes.md),
              child: _buildTrendRow(point, controller.selectedMetricUnit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow(TestMetricTrendPoint point, String unit) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${point.reportDate.day}/${point.reportDate.month}/${point.reportDate.year}',
            style: Get.textTheme.bodyMedium,
          ),
        ),
        Text(
          '${point.value.toStringAsFixed(2)}${unit.isEmpty ? '' : ' $unit'}',
          style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMessageState({
    required String title,
    required String subtitle,
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
                style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
                textAlign: TextAlign.center,
              ),
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
