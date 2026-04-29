import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/authentication/authentication_repository.dart';
import 'package:mindheal/data/repositories/test_reports/test_report_repository.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/features/test_reports/models/test_report_model.dart';
import 'package:mindheal/features/test_reports/models/test_report_template_model.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:uuid/uuid.dart';

class TestReportFormController extends GetxController {
  static TestReportFormController get instance => Get.find();

  final TestReportRepository _repository = Get.put(TestReportRepository());
  final UserController _userController = Get.find<UserController>();
  final Uuid _uuid = const Uuid();
  late String _workingReportId;
  final formKey = GlobalKey<FormState>();

  final selectedPatientId = ''.obs;
  final selectedReportType = TestReportType.cbc.obs;
  final selectedStatus = TestReportStatus.draft.obs;
  final selectedReportDate = DateTime.now().obs;
  final metrics = <TestMetricModel>[].obs;
  final attachmentUrls = <String>[].obs;
  final isSaving = false.obs;
  final isUploading = false.obs;
  final summaryController = TextEditingController();
  final notesController = TextEditingController();
  final labNameController = TextEditingController();
  final selectedPatient = Rxn<UserModel>();

  List<UserModel> get allPatients => _userController.allPatients;
  bool get isLoadingPatients => _userController.isLoadingPatients;
  bool get isDoctor => _userController.isDoctor();

  @override
  void onInit() {
    super.onInit();
    _initializeWorkingReport();
    if (_userController.allPatients.isEmpty) {
      _userController.loadAllPatients();
    }
  }

  void _initializeWorkingReport() {
    _workingReportId = _uuid.v4();
    selectedPatientId.value = '';
    selectedPatient.value = null;
    selectedStatus.value = TestReportStatus.draft;
    selectedReportDate.value = DateTime.now();
    summaryController.clear();
    notesController.clear();
    labNameController.clear();
    attachmentUrls.clear();
    loadTemplate(selectedReportType.value);
  }

  void loadTemplate(TestReportType reportType) {
    selectedReportType.value = reportType;
    final template = TTestReportTemplates.templateFor(reportType);
    metrics.assignAll(
      template.metrics.map((metric) => metric.toMetricModel()).toList(),
    );
  }

  void selectPatient(String patientId) {
    selectedPatientId.value = patientId;
    selectedPatient.value = _userController.allPatients.firstWhereOrNull(
      (patient) => patient.id == patientId,
    );
  }

  void setReportStatus(TestReportStatus status) {
    selectedStatus.value = status;
  }

  void setReportDate(DateTime date) {
    selectedReportDate.value = date;
  }

  void updateMetricValue(String metricKey, String rawValue) {
    final index = metrics.indexWhere((metric) => metric.metricKey == metricKey);
    if (index == -1) return;

    final parsedValue = double.tryParse(rawValue.trim());
    final current = metrics[index];
    metrics[index] = current.copyWith(
      value: parsedValue,
      flag: _calculateFlag(
        value: parsedValue,
        min: current.referenceMin,
        max: current.referenceMax,
      ),
    );
  }

  bool validateBeforeSave() {
    final isFormValid = formKey.currentState?.validate() ?? false;
    if (!isFormValid) return false;

    if (selectedPatientId.value.isEmpty) {
      Get.snackbar(
        'Patient Required',
        'Please select a patient before saving the report.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    final hasAtLeastOneMetric = metrics.any((metric) => metric.value != null);
    if (!hasAtLeastOneMetric) {
      Get.snackbar(
        'Metric Required',
        'Please enter at least one test value before saving the report.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  TestReportModel buildReport() {
    final doctor = _userController.user.value;
    return TestReportModel(
      id: _workingReportId,
      patientId: selectedPatientId.value,
      doctorId: doctor.id.isEmpty ? AuthenticationRepository.instance.getUserID : doctor.id,
      doctorName: doctor.fullName.isEmpty ? 'Doctor' : doctor.fullName,
      reportType: selectedReportType.value,
      labName: labNameController.text.trim(),
      reportDate: selectedReportDate.value,
      summary: summaryController.text.trim(),
      notes: notesController.text.trim(),
      attachmentUrls: attachmentUrls.toList(),
      status: selectedStatus.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metrics: metrics.toList(),
    );
  }

  Future<void> saveReport({required TestReportStatus status}) async {
    if (!validateBeforeSave()) return;

    try {
      isSaving.value = true;
      selectedStatus.value = status;
      final report = buildReport();
      await _repository.createTestReport(report);

      Get.snackbar(
        'Success',
        status == TestReportStatus.draft
            ? 'Test report draft saved successfully.'
            : 'Test report submitted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _initializeWorkingReport();
    } catch (e) {
      Get.snackbar(
        'Save Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> uploadAttachment({
    required String filePath,
    String? fileName,
  }) async {
    try {
      isUploading.value = true;
      final url = await _repository.uploadReportAttachment(
        filePath: filePath,
        reportId: _workingReportId,
        fileName: fileName,
      );
      attachmentUrls.add(url);
      Get.snackbar(
        'Attachment Added',
        'Report file uploaded successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Upload Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  void removeAttachment(String url) {
    attachmentUrls.remove(url);
  }

  @override
  void onClose() {
    summaryController.dispose();
    notesController.dispose();
    labNameController.dispose();
    super.onClose();
  }

  TestMetricFlag _calculateFlag({
    required double? value,
    required double? min,
    required double? max,
  }) {
    if (value == null || min == null || max == null) return TestMetricFlag.unknown;
    if (value < min) return TestMetricFlag.low;
    if (value > max) return TestMetricFlag.high;
    return TestMetricFlag.normal;
  }
}
