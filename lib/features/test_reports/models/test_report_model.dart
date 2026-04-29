import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/formatters/formatter.dart';

class TestReportModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final TestReportType reportType;
  final String labName;
  final DateTime reportDate;
  final String summary;
  final String notes;
  final List<String> attachmentUrls;
  final TestReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TestMetricModel> metrics;

  const TestReportModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.reportType,
    required this.labName,
    required this.reportDate,
    this.summary = '',
    this.notes = '',
    this.attachmentUrls = const [],
    this.status = TestReportStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.metrics = const [],
  });

  static TestReportModel empty() => TestReportModel(
        id: '',
        patientId: '',
        doctorId: '',
        doctorName: '',
        reportType: TestReportType.cbc,
        labName: '',
        reportDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  String get formattedReportDate => TFormatter.formatDate(reportDate);

  String get reportTypeLabel {
    switch (reportType) {
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'reportType': reportType.name,
      'labName': labName,
      'reportDate': reportDate,
      'summary': summary,
      'notes': notes,
      'attachmentUrls': attachmentUrls,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'metrics': metrics.map((metric) => metric.toJson()).toList(),
    };
  }

  factory TestReportModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestReportModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      reportType: TestReportType.values.firstWhere(
        (value) => value.name == data['reportType'],
        orElse: () => TestReportType.cbc,
      ),
      labName: data['labName'] ?? '',
      reportDate: _toDateTime(data['reportDate']) ?? DateTime.now(),
      summary: data['summary'] ?? '',
      notes: data['notes'] ?? '',
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      status: TestReportStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => TestReportStatus.draft,
      ),
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTime(data['updatedAt']) ?? DateTime.now(),
      metrics: (data['metrics'] as List<dynamic>? ?? [])
          .map((metric) => TestMetricModel.fromJson(metric as Map<String, dynamic>))
          .toList(),
    );
  }

  TestReportModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    TestReportType? reportType,
    String? labName,
    DateTime? reportDate,
    String? summary,
    String? notes,
    List<String>? attachmentUrls,
    TestReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TestMetricModel>? metrics,
  }) {
    return TestReportModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      reportType: reportType ?? this.reportType,
      labName: labName ?? this.labName,
      reportDate: reportDate ?? this.reportDate,
      summary: summary ?? this.summary,
      notes: notes ?? this.notes,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metrics: metrics ?? this.metrics,
    );
  }

  List<TestMetricModel> get abnormalMetrics => metrics
      .where(
        (metric) => metric.flag == TestMetricFlag.high || metric.flag == TestMetricFlag.low,
      )
      .toList();

  static DateTime? _toDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
