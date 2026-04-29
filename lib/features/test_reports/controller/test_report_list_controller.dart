import 'package:get/get.dart';
import 'package:mindheal/data/repositories/test_reports/test_report_repository.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/features/test_reports/models/test_report_model.dart';
import 'package:mindheal/utils/constants/enums.dart';

class TestReportListController extends GetxController {
  static TestReportListController get instance => Get.find();

  final TestReportRepository _repository = Get.put(TestReportRepository());
  final UserController _userController = Get.find<UserController>();

  final reports = <TestReportModel>[].obs;
  final isLoading = false.obs;
  final selectedReportType = Rxn<TestReportType>();
  final searchQuery = ''.obs;
  final errorMessage = ''.obs;
  final patientNames = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _userController.user.value;
      if (user.role == AppRole.doctor) {
        reports.value = await _repository.getDoctorReports(user.id);
      } else if (user.role == AppRole.patient) {
        reports.value = await _repository.getPatientReports(user.id);
      } else if (user.role == AppRole.caregiver) {
        reports.value = await _repository.getReportsForPatientIds(user.patientIds ?? []);
      } else {
        reports.clear();
      }

      await _loadPatientNames();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  List<TestReportModel> get filteredReports {
    var items = reports.toList();

    if (selectedReportType.value != null) {
      items = items.where((report) => report.reportType == selectedReportType.value).toList();
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((report) {
        final patientName = getPatientName(report.patientId).toLowerCase();
        return report.reportTypeLabel.toLowerCase().contains(query) ||
            report.labName.toLowerCase().contains(query) ||
            report.doctorName.toLowerCase().contains(query) ||
            patientName.contains(query);
      }).toList();
    }

    return items;
  }

  void filterByType(TestReportType? type) {
    selectedReportType.value = type;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  String getPatientName(String patientId) {
    return patientNames[patientId] ?? 'Patient';
  }

  bool get canCreateReports => _userController.isDoctor();

  AppRole get currentUserRole => _userController.user.value.role;

  String get screenTitle {
    switch (currentUserRole) {
      case AppRole.doctor:
        return 'Created Test Reports';
      case AppRole.patient:
        return 'My Test Reports';
      case AppRole.caregiver:
        return 'Patient Test Reports';
      case AppRole.admin:
        return 'Test Reports';
    }
  }

  Future<void> refreshReports() async {
    await loadReports();
  }

  Future<void> _loadPatientNames() async {
    patientNames.clear();

    final patientIds = reports.map((report) => report.patientId).toSet().where((id) => id.isNotEmpty).toList();
    if (patientIds.isEmpty) return;

    final List<UserModel> users = await _userController.getUsersByIds(patientIds);
    for (final user in users) {
      patientNames[user.id] = user.fullName.isEmpty ? user.email : user.fullName;
    }
  }
}
