import 'package:get/get.dart';
import 'package:mindheal/data/repositories/test_reports/test_report_repository.dart';
import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/features/test_reports/models/test_report_model.dart';
import 'package:mindheal/utils/constants/enums.dart';

class TestReportDetailController extends GetxController {
  static TestReportDetailController get instance => Get.find();

  final TestReportRepository _repository = Get.put(TestReportRepository());

  final currentReport = Rxn<TestReportModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> loadReport(String reportId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentReport.value = await _repository.getReportById(reportId);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  List<TestMetricModel> get abnormalMetrics {
    return currentReport.value?.abnormalMetrics ?? [];
  }

  List<TestMetricModel> get normalMetrics {
    final report = currentReport.value;
    if (report == null) return [];
    return report.metrics.where((metric) => metric.flag == TestMetricFlag.normal).toList();
  }
}
