import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/utils/constants/enums.dart';

class TestMetricTemplateModel {
  final String metricKey;
  final String metricLabel;
  final String unit;
  final double? referenceMin;
  final double? referenceMax;
  final int displayOrder;

  const TestMetricTemplateModel({
    required this.metricKey,
    required this.metricLabel,
    this.unit = '',
    this.referenceMin,
    this.referenceMax,
    required this.displayOrder,
  });

  TestMetricModel toMetricModel() {
    return TestMetricModel(
      metricKey: metricKey,
      metricLabel: metricLabel,
      unit: unit,
      referenceMin: referenceMin,
      referenceMax: referenceMax,
      displayOrder: displayOrder,
    );
  }
}

class TestReportTemplateModel {
  final TestReportType reportType;
  final String title;
  final List<TestMetricTemplateModel> metrics;

  const TestReportTemplateModel({
    required this.reportType,
    required this.title,
    required this.metrics,
  });
}

class TTestReportTemplates {
  static final List<TestReportTemplateModel> templates = [
    TestReportTemplateModel(
      reportType: TestReportType.cbc,
      title: 'Complete Blood Count',
      metrics: const [
        TestMetricTemplateModel(metricKey: 'hemoglobin', metricLabel: 'Hemoglobin', unit: 'g/dL', referenceMin: 12, referenceMax: 17.5, displayOrder: 1),
        TestMetricTemplateModel(metricKey: 'wbc', metricLabel: 'WBC', unit: 'x10^9/L', referenceMin: 4, referenceMax: 11, displayOrder: 2),
        TestMetricTemplateModel(metricKey: 'platelets', metricLabel: 'Platelets', unit: 'x10^9/L', referenceMin: 150, referenceMax: 450, displayOrder: 3),
      ],
    ),
    TestReportTemplateModel(
      reportType: TestReportType.bloodGlucose,
      title: 'Blood Glucose',
      metrics: const [
        TestMetricTemplateModel(metricKey: 'fasting_glucose', metricLabel: 'Fasting Glucose', unit: 'mg/dL', referenceMin: 70, referenceMax: 99, displayOrder: 1),
        TestMetricTemplateModel(metricKey: 'random_glucose', metricLabel: 'Random Glucose', unit: 'mg/dL', referenceMin: 70, referenceMax: 140, displayOrder: 2),
        TestMetricTemplateModel(metricKey: 'hba1c', metricLabel: 'HbA1c', unit: '%', referenceMin: 4, referenceMax: 5.6, displayOrder: 3),
      ],
    ),
    TestReportTemplateModel(
      reportType: TestReportType.lipidProfile,
      title: 'Lipid Profile',
      metrics: const [
        TestMetricTemplateModel(metricKey: 'total_cholesterol', metricLabel: 'Total Cholesterol', unit: 'mg/dL', referenceMin: 125, referenceMax: 200, displayOrder: 1),
        TestMetricTemplateModel(metricKey: 'ldl', metricLabel: 'LDL', unit: 'mg/dL', referenceMin: 0, referenceMax: 100, displayOrder: 2),
        TestMetricTemplateModel(metricKey: 'hdl', metricLabel: 'HDL', unit: 'mg/dL', referenceMin: 40, referenceMax: 60, displayOrder: 3),
        TestMetricTemplateModel(metricKey: 'triglycerides', metricLabel: 'Triglycerides', unit: 'mg/dL', referenceMin: 0, referenceMax: 150, displayOrder: 4),
      ],
    ),
    TestReportTemplateModel(
      reportType: TestReportType.thyroid,
      title: 'Thyroid Function',
      metrics: const [
        TestMetricTemplateModel(metricKey: 'tsh', metricLabel: 'TSH', unit: 'mIU/L', referenceMin: 0.4, referenceMax: 4.0, displayOrder: 1),
        TestMetricTemplateModel(metricKey: 't3', metricLabel: 'T3', unit: 'ng/dL', referenceMin: 80, referenceMax: 200, displayOrder: 2),
        TestMetricTemplateModel(metricKey: 't4', metricLabel: 'T4', unit: 'ug/dL', referenceMin: 5, referenceMax: 12, displayOrder: 3),
      ],
    ),
    TestReportTemplateModel(
      reportType: TestReportType.liverFunction,
      title: 'Liver Function',
      metrics: const [
        TestMetricTemplateModel(metricKey: 'alt', metricLabel: 'ALT', unit: 'U/L', referenceMin: 7, referenceMax: 56, displayOrder: 1),
        TestMetricTemplateModel(metricKey: 'ast', metricLabel: 'AST', unit: 'U/L', referenceMin: 10, referenceMax: 40, displayOrder: 2),
        TestMetricTemplateModel(metricKey: 'bilirubin', metricLabel: 'Bilirubin', unit: 'mg/dL', referenceMin: 0.1, referenceMax: 1.2, displayOrder: 3),
      ],
    ),
  ];

  static TestReportTemplateModel templateFor(TestReportType reportType) {
    return templates.firstWhere(
      (template) => template.reportType == reportType,
      orElse: () => templates.first,
    );
  }
}
