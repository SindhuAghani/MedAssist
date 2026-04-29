import 'package:mindheal/utils/constants/enums.dart';

class TestMetricModel {
  final String metricKey;
  final String metricLabel;
  final double? value;
  final String unit;
  final double? referenceMin;
  final double? referenceMax;
  final TestMetricFlag flag;
  final int displayOrder;

  const TestMetricModel({
    required this.metricKey,
    required this.metricLabel,
    this.value,
    this.unit = '',
    this.referenceMin,
    this.referenceMax,
    this.flag = TestMetricFlag.unknown,
    this.displayOrder = 0,
  });

  static TestMetricModel empty() => const TestMetricModel(
        metricKey: '',
        metricLabel: '',
      );

  Map<String, dynamic> toJson() {
    return {
      'metricKey': metricKey,
      'metricLabel': metricLabel,
      'value': value,
      'unit': unit,
      'referenceMin': referenceMin,
      'referenceMax': referenceMax,
      'flag': flag.name,
      'displayOrder': displayOrder,
    };
  }

  factory TestMetricModel.fromJson(Map<String, dynamic> json) {
    return TestMetricModel(
      metricKey: json['metricKey'] ?? '',
      metricLabel: json['metricLabel'] ?? '',
      value: _toDouble(json['value']),
      unit: json['unit'] ?? '',
      referenceMin: _toDouble(json['referenceMin']),
      referenceMax: _toDouble(json['referenceMax']),
      flag: TestMetricFlag.values.firstWhere(
        (value) => value.name == json['flag'],
        orElse: () => TestMetricFlag.unknown,
      ),
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  TestMetricModel copyWith({
    String? metricKey,
    String? metricLabel,
    double? value,
    String? unit,
    double? referenceMin,
    double? referenceMax,
    TestMetricFlag? flag,
    int? displayOrder,
  }) {
    return TestMetricModel(
      metricKey: metricKey ?? this.metricKey,
      metricLabel: metricLabel ?? this.metricLabel,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      referenceMin: referenceMin ?? this.referenceMin,
      referenceMax: referenceMax ?? this.referenceMax,
      flag: flag ?? this.flag,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  bool get hasValue => value != null;

  static double? _toDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw.toDouble();
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}

class TestMetricTrendPoint {
  final DateTime reportDate;
  final double value;
  final String reportId;

  const TestMetricTrendPoint({
    required this.reportDate,
    required this.value,
    required this.reportId,
  });
}
