import 'package:get/get.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/data/repositories/test_reports/test_report_repository.dart';
import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/features/test_reports/models/test_report_model.dart';
import 'package:mindheal/utils/constants/enums.dart';

class TestReportAnalyticsController extends GetxController {
  static TestReportAnalyticsController get instance => Get.find();

  final TestReportRepository _repository = Get.put(TestReportRepository());
  final UserController _userController = Get.find<UserController>();

  final reports = <TestReportModel>[].obs;
  final availablePatients = <UserModel>[].obs;
  final selectedReportType = TestReportType.cbc.obs;
  final selectedPatientId = ''.obs;
  final selectedMetricKey = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeAnalytics();
  }

  Future<void> initializeAnalytics() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final currentUser = _userController.user.value;
      if (currentUser.role == AppRole.patient) {
        availablePatients.assignAll([currentUser]);
        selectedPatientId.value = currentUser.id;
      } else if (currentUser.role == AppRole.doctor) {
        if (_userController.allPatients.isEmpty) {
          await _userController.loadAllPatients();
        }
        availablePatients.assignAll(_userController.allPatients);
        if (availablePatients.isNotEmpty) {
          selectedPatientId.value = availablePatients.first.id;
        }
      } else if (currentUser.role == AppRole.caregiver) {
        final patientIds = currentUser.patientIds ?? [];
        if (patientIds.isNotEmpty) {
          availablePatients.assignAll(await _userController.getUsersByIds(patientIds));
          if (availablePatients.isNotEmpty) {
            selectedPatientId.value = availablePatients.first.id;
          }
        }
      }

      if (selectedPatientId.value.isNotEmpty) {
        await loadAnalytics();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAnalytics() async {
    if (selectedPatientId.value.isEmpty) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      reports.value = await _repository.getReportsByPatientAndType(
        patientId: selectedPatientId.value,
        reportType: selectedReportType.value,
      );

      final available = availableMetrics;
      if (available.isNotEmpty) {
        final currentlySelectedExists = available.any((metric) => metric.metricKey == selectedMetricKey.value);
        if (!currentlySelectedExists) {
          selectedMetricKey.value = available.first.metricKey;
        }
      } else {
        selectedMetricKey.value = '';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void setPatient(String? patientId) {
    if (patientId == null || patientId.isEmpty) return;
    selectedPatientId.value = patientId;
    loadAnalytics();
  }

  void setReportType(TestReportType? reportType) {
    if (reportType == null) return;
    selectedReportType.value = reportType;
    loadAnalytics();
  }

  void setMetricKey(String? metricKey) {
    if (metricKey == null || metricKey.isEmpty) return;
    selectedMetricKey.value = metricKey;
  }

  List<TestMetricModel> get availableMetrics {
    final Map<String, TestMetricModel> uniqueMetrics = {};
    for (final report in reports) {
      for (final metric in report.metrics) {
        uniqueMetrics.putIfAbsent(metric.metricKey, () => metric);
      }
    }
    final items = uniqueMetrics.values.toList();
    items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return items;
  }

  List<TestMetricTrendPoint> get selectedMetricTrend {
    if (selectedMetricKey.value.isEmpty) return [];

    final trendPoints = <TestMetricTrendPoint>[];
    for (final report in reports) {
      final metric = report.metrics.firstWhereOrNull(
        (item) => item.metricKey == selectedMetricKey.value && item.value != null,
      );
      if (metric?.value != null) {
        trendPoints.add(
          TestMetricTrendPoint(
            reportDate: report.reportDate,
            value: metric!.value!,
            reportId: report.id,
          ),
        );
      }
    }
    return trendPoints;
  }

  String get selectedPatientName {
    final patient = availablePatients.firstWhereOrNull(
      (item) => item.id == selectedPatientId.value,
    );
    if (patient == null) return 'Patient';
    return patient.fullName.isEmpty ? patient.email : patient.fullName;
  }

  String get selectedMetricLabel {
    final metric = availableMetrics.firstWhereOrNull(
      (item) => item.metricKey == selectedMetricKey.value,
    );
    return metric?.metricLabel ?? 'Metric';
  }

  String get selectedMetricUnit {
    final metric = availableMetrics.firstWhereOrNull(
      (item) => item.metricKey == selectedMetricKey.value,
    );
    return metric?.unit ?? '';
  }

  String get trendSummary {
    final trend = selectedMetricTrend;
    if (trend.length < 2) return 'Not enough data points to determine a trend yet.';

    final first = trend.first.value;
    final last = trend.last.value;
    if (last > first) {
      return 'This metric is trending upward over time.';
    }
    if (last < first) {
      return 'This metric is trending downward over time.';
    }
    return 'This metric is stable across the available reports.';
  }
}
