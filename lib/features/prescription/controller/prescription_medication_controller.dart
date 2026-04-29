import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/prescription/prescription_repository.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/enums.dart';

class PatientMedicationsController extends GetxController {
  // Dependencies
  final PrescriptionRepository _prescriptionRepo = Get.put(PrescriptionRepository());
  final UserController _userController = Get.put(UserController());

  // Rx variables
  final RxList<PrescriptionModel> _prescriptions = <PrescriptionModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<PrescriptionModel> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    loadMedications();
  }

  /// Load patient's medications
  Future<void> loadMedications() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final currentUser = _userController.user;

      // Load prescriptions for current patient
      _prescriptions.value = await _prescriptionRepo.getPatientPrescriptions(currentUser.value.id);

    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get today's medications
  List<Medication> getTodaysMedications() {
    final today = DateTime.now();
    List<Medication> todaysMeds = [];

    for (var prescription in _prescriptions) {
      if (prescription.status == PrescriptionStatus.active) {
        for (var medication in prescription.medications) {
          // Check if medication is active today
          if (medication.startDate.isBefore(today) &&
              (medication.endDate == null || medication.endDate!.isAfter(today))) {
            todaysMeds.add(medication);
          }
        }
      }
    }

    return todaysMeds;
  }

  /// Get medications by date
  List<Medication> getMedicationsByDate(DateTime date) {
    List<Medication> meds = [];

    for (var prescription in _prescriptions) {
      if (prescription.status == PrescriptionStatus.active) {
        for (var medication in prescription.medications) {
          // Check if medication is active on given date
          if (medication.startDate.isBefore(date) &&
              (medication.endDate == null || medication.endDate!.isAfter(date))) {
            meds.add(medication);
          }
        }
      }
    }

    return meds;
  }

  /// Mark medication as taken
  Future<void> markMedicationTaken(String medicationId, DateTime takenAt) async {
    try {
      // TODO: Implement medication tracking in database
      // For now, just show success message
      Get.snackbar(
        'Success',
        'Medication marked as taken',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark medication: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Refresh medications
  Future<void> refresh() async {
    await loadMedications();
  }
}