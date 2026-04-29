import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/authentication/authentication_repository.dart';
import 'package:mindheal/data/repositories/prescription/prescription_repository.dart';
import 'package:mindheal/data/repositories/user/user_repository.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/local_storage/storage_utility.dart';

class CaregiverController extends GetxController {
  static CaregiverController get instance => Get.find();

  // Repositories
  final PrescriptionRepository _prescriptionRepo = Get.put(PrescriptionRepository());

  // Rx variables
  final RxList<UserModel> _patients = <UserModel>[].obs;
  final RxList<PrescriptionModel> _prescriptions = <PrescriptionModel>[].obs;
  final Rx<UserModel?> _selectedPatient = Rx<UserModel?>(null);
  final Rx<PrescriptionModel?> _selectedPrescription = Rx<PrescriptionModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxInt _activeTabIndex = 0.obs; // 0: Dashboard, 1: Patients, 2: Calendar

  // Getters
  List<UserModel> get patients => _patients;
  List<PrescriptionModel> get prescriptions => _prescriptions;
  UserModel? get selectedPatient => _selectedPatient.value;
  PrescriptionModel? get selectedPrescription => _selectedPrescription.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  int get activeTabIndex => _activeTabIndex.value;

  // Statistics
  RxInt get totalPatients => _patients.length.obs;
  RxInt get activePrescriptions => _prescriptions.where((p) => p.status == PrescriptionStatus.active).length.obs;
  RxInt get pendingActions => _prescriptions.where((p) =>
  p.status == PrescriptionStatus.pendingReview ||
      p.medications.any((m) => m.endDate?.isBefore(DateTime.now()) ?? false)
  ).length.obs;
  RxInt get todayMedications => _prescriptions
      .expand((p) => p.medications)
      .where((m) => m.startDate.isBefore(DateTime.now()) &&
      (m.endDate == null || m.endDate!.isAfter(DateTime.now())))
      .length.obs;

  @override
  void onInit() {
    super.onInit();
    loadCaregiverData();
  }

  /// Load all data for caregiver
  Future<void> loadCaregiverData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';


      // Load patients and prescriptions in parallel
      await Future.wait([
        _loadPatients(AuthenticationRepository.instance.getUserID),
        _loadPrescriptions(AuthenticationRepository.instance.getUserID),
      ]);

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

  /// Load patients managed by caregiver
  Future<void> _loadPatients(String caregiverId) async {
    _patients.value = await _prescriptionRepo.getCaregiverPatients(caregiverId);
    if (_patients.isNotEmpty && _selectedPatient.value == null) {
      _selectedPatient.value = _patients.first;
    }
  }

  /// Load prescriptions managed by caregiver
  Future<void> _loadPrescriptions(String caregiverId) async {
    _prescriptions.value = await _prescriptionRepo.getCaregiverPrescriptions(caregiverId);
  }

  /// Select a patient
  void selectPatient(UserModel patient) {
    _selectedPatient.value = patient;
    _loadPatientPrescriptions(patient.id);
  }

  /// Load prescriptions for selected patient
  Future<void> _loadPatientPrescriptions(String patientId) async {
    try {
      _isLoading.value = true;
      final patientPrescriptions = await _prescriptionRepo.getPatientPrescriptions(patientId);

      // Filter only prescriptions managed by current caregiver
      final caregiverId = AuthenticationRepository.instance.getUserID;
      _prescriptions.value = patientPrescriptions
          .where((p) => p.caregiverId == caregiverId)
          .toList();
    } catch (e) {
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get prescriptions for a specific patient
  List<PrescriptionModel> getPrescriptionsForPatient(String patientId) {
    return _prescriptions.where((p) {
      print('Patient ID: $patientId, Prescription Patient ID: ${p.patientId}');
      return p.patientId == patientId;
    }).toList();
  }

  /// Get medications due today for a patient
  List<Medication> getTodayMedicationsForPatient(String patientId) {
    final today = DateTime.now();
    final prescriptions = getPrescriptionsForPatient(patientId);

    return prescriptions
        .expand((p) => p.medications)
        .where((med) =>
    med.startDate.isBefore(today) &&
        (med.endDate == null || med.endDate!.isAfter(today)) &&
        med.timings.isNotEmpty)
        .toList();
  }

  /// Add new patient to caregiver's list
  Future<void> addPatient(UserModel patient) async {
    try {
      _isLoading.value = true;
      final _repo = Get.put(UserRepository());

      // Get caregiver ID
      final caregiverId = AuthenticationRepository.instance.getUserID;

      // Find prescriptions for this patient and assign caregiver
      final patientPrescriptions = await _prescriptionRepo.getPatientPrescriptions(patient.id);
      for (var prescription in patientPrescriptions) {
        if (prescription.caregiverId.isEmpty) {
          await _prescriptionRepo.assignCaregiver(prescription.id, caregiverId!, 'Caregiver');
        }
      }

      // Add caregiver to patient
      await _repo.updateUser(patient.id, {
        'caregiverIds': FieldValue.arrayUnion([caregiverId]),
      });

      // add patient to caregiver
       await _repo.updateUser(AuthenticationRepository.instance.getUserID, {
        'patientIds' : FieldValue.arrayUnion([patient.id]),
      });



      // Reload data
      await loadCaregiverData();

      Get.snackbar(
        'Success',
        'Patient added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Remove patient from caregiver's list
  Future<void> removePatient(String patientId) async {
    try {
      _isLoading.value = true;
      final _repo = Get.put(UserRepository());


      // Remove caregiver from all patient's prescriptions
      final prescriptions = getPrescriptionsForPatient(patientId);
      for (var prescription in prescriptions) {
        await _prescriptionRepo.assignCaregiver(prescription.id, '', '');
      }

      // Remove from local list
      _patients.removeWhere((p) => p.id == patientId);
      if (_selectedPatient.value?.id == patientId) {
        _selectedPatient.value = _patients.isNotEmpty ? _patients.first : null;
      }

      // Remove caregiver to patient
      await _repo.updateUser(patientId, {
        'caregiverIds': FieldValue.arrayRemove([AuthenticationRepository.instance.getUserID]),
      });

      // Remove patient to caregiver
      await _repo.updateUser(AuthenticationRepository.instance.getUserID, {
        'patientIds' : FieldValue.arrayRemove([patientId]),
      });



      Get.snackbar(
        'Success',
        'Patient removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update prescription status
  Future<void> updatePrescriptionStatus(
      String prescriptionId,
      PrescriptionStatus status
      ) async {
    try {
      await _prescriptionRepo.updatePrescriptionStatus(prescriptionId, status);

      // Update local list
      final index = _prescriptions.indexWhere((p) => p.id == prescriptionId);
      if (index != -1) {
        _prescriptions[index] = _prescriptions[index].copyWith(status: status);
        _prescriptions.refresh();
      }
    } catch (e) {
      _errorMessage.value = e.toString();
    }
  }

  /// Mark medication as taken
  Future<void> markMedicationTaken(String medicationId, DateTime takenAt) async {
    // In real app, you would save this to Firestore
    // For now, we'll update local state
    Get.snackbar(
      'Success',
      'Medication marked as taken',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// Change active tab
  void changeTab(int index) {
    _activeTabIndex.value = index;
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  /// Refresh data
  Future<void> refreshData() async {
    await loadCaregiverData();
  }
}