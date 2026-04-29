import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/prescription/prescription_repository.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/enums.dart';

class PrescriptionDetailsController extends GetxController {
  // Dependencies
  final PrescriptionRepository _prescriptionRepo = PrescriptionRepository.instance;
  final UserController _userController = Get.find<UserController>();

  // Rx variables
  final Rx<PrescriptionModel?> _prescription = Rx<PrescriptionModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isSharing = false.obs;

  // Getters
  PrescriptionModel? get prescription => _prescription.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isSharing => _isSharing.value;

  /// Load prescription details by ID
  Future<void> loadPrescriptionDetails(String prescriptionId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final prescription = await _prescriptionRepo.getPrescriptionById(prescriptionId);

      // Check if current user has access to this prescription
      final currentUser = _userController.user;
      final hasAccess = _checkAccessPermissions(currentUser.value.id, prescription);
      if (!hasAccess) {
        throw 'You do not have permission to view this prescription';
      }

      _prescription.value = prescription;

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

  /// Check if user has access to view prescription
  bool _checkAccessPermissions(String userId, PrescriptionModel prescription) {
    // Patient can view their own prescriptions
    if (prescription.patientId == userId) return true;

    // Doctor can view prescriptions they wrote
    if (prescription.doctorId == userId) return true;

    // Caregiver can view prescriptions assigned to them
    if (prescription.caregiverId == userId) return true;

    // Admin can view all prescriptions
    final currentUser = _userController.user;
    if (currentUser.value.role == AppRole.admin) return true;

    return false;
  }

  /// Share prescription
  Future<void> sharePrescription() async {
    try {
      _isSharing.value = true;

      // TODO: Implement actual sharing functionality
      // This could be:
      // 1. Generate PDF
      // 2. Share as text
      // 3. Share image

      await Future.delayed(const Duration(seconds: 1)); // Simulate sharing

      Get.snackbar(
        'Success',
        'Prescription shared successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share prescription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSharing.value = false;
    }
  }

  /// Delete prescription
  Future<void> deletePrescription() async {
    try {
      if (_prescription.value == null) return;

      _isLoading.value = true;

      await _prescriptionRepo.deletePrescription(_prescription.value!.id);

      // Clear local state
      _prescription.value = null;

    } catch (e) {
      throw 'Failed to delete prescription: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update prescription status
  Future<void> updatePrescriptionStatus(PrescriptionStatus newStatus) async {
    try {
      if (_prescription.value == null) return;

      await _prescriptionRepo.updatePrescriptionStatus(
        _prescription.value!.id,
        newStatus,
      );

      // Update local prescription
      _prescription.value = _prescription.value!.copyWith(status: newStatus);
      _prescription.refresh();

      Get.snackbar(
        'Success',
        'Prescription status updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Mark medication as taken
  Future<void> markMedicationTaken(String medicationId) async {
    try {
      // TODO: Implement medication tracking
      // This should update a separate collection for medication adherence

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

  /// Add note to prescription
  Future<void> addNote(String note) async {
    try {
      if (_prescription.value == null) return;

      // TODO: Implement note adding to prescription
      // This could be a separate collection or added to prescription notes

      Get.snackbar(
        'Success',
        'Note added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add note: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Refresh prescription data
  @override
  Future<void> refresh() async {
    if (_prescription.value != null) {
      await loadPrescriptionDetails(_prescription.value!.id);
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }
}