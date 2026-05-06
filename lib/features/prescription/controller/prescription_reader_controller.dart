import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindheal/data/repositories/prescription/prescription_repository.dart';
import 'package:mindheal/data/repositories/reminders/medication_dose_repository.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/routes/routes.dart';
import 'package:mindheal/services/ocr/ocr_service.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:translator/translator.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:uuid/uuid.dart';

class PrescriptionReaderController extends GetxController {
  // Dependencies
  final PrescriptionRepository _prescriptionRepo = Get.put(
    PrescriptionRepository(),
  );
  final MedicationDoseRepository _doseRepo = Get.put(
    MedicationDoseRepository(),
  );
  final UserController _userController = Get.put(UserController());
  final OcrService _ocrService = OcrService();

  // Reactive variables
  final Rx<File?> _prescriptionImage = Rx<File?>(null);
  final Rx<String> _prescriptionImageUrl = ''.obs;
  final RxString _extractedText = ''.obs;
  final RxString _simplifiedText = ''.obs;
  final RxString _translatedText = ''.obs;
  final RxBool _isProcessing = false.obs;
  final RxBool _isSaving = false.obs;
  final RxBool _isTranslating = false.obs;
  final RxString _errorMessage = ''.obs;
  final Rx<PrescriptionModel> _editingPrescription =
      PrescriptionModel.empty().obs;
  final RxBool _isEditMode = false.obs;
  final Rx<PrescriptionModel?> _currentPrescription = Rx<PrescriptionModel?>(
    null,
  );
  final RxList<Medication> _extractedMedications = <Medication>[].obs;

  // Getters
  File? get prescriptionImage => _prescriptionImage.value;
  String get extractedText => _extractedText.value;
  String get simplifiedText => _simplifiedText.value;
  String get translatedText => _translatedText.value;
  bool get isProcessing => _isProcessing.value;
  bool get isSaving => _isSaving.value;
  bool get isTranslating => _isTranslating.value;
  String get errorMessage => _errorMessage.value;
  PrescriptionModel? get currentPrescription => _currentPrescription.value;
  List<Medication> get extractedMedications => _extractedMedications;
  PrescriptionModel get editingPrescription => _editingPrescription.value;
  bool get isEditMode => _isEditMode.value;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final GoogleTranslator _translator = GoogleTranslator();

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        _prescriptionImage.value = File(image.path);
        _errorMessage.value = '';
        await _processImage(File(image.path));
      }
    } catch (e) {
      _errorMessage.value = 'Failed to capture image: $e';
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        _prescriptionImage.value = File(image.path);
        _errorMessage.value = '';
        await _processImage(File(image.path));
      }
    } catch (e) {
      _errorMessage.value = 'Failed to pick image: $e';
    }
  }

  /// Process image using OCR and save to Firebase
  Future<void> _processImage(File imageFile) async {
    _isProcessing.value = true;
    _extractedText.value = '';
    _simplifiedText.value = '';
    _translatedText.value = '';
    _extractedMedications.clear();

    try {
      final currentUser = _userController.user.value;
      final result = await _ocrService.scanPrescription(
        imageFile: imageFile,
        userId: currentUser.id,
      );

      _prescriptionImageUrl.value = result.imageUrl;
      _extractedText.value = result.rawText;
      _extractedMedications.assignAll(result.medications);
      _simplifiedText.value = _buildMedicationSummary(
        result.medications,
        result.rawText,
      );

      if (result.medicineExtractionFailed) {
        _showMedicineExtractionFailedSnackBar();
      }

      if (_extractedText.isNotEmpty) {
        Get.toNamed(
          TRoutes.prescriptionResults,
          arguments: {
            'extractedText': _extractedText.value,
            'simplifiedText': _simplifiedText.value,
            'medications': _extractedMedications,
            'imageUrl': result.imageUrl,
          },
        );
      }
    } on EmptyOcrTextException {
      _errorMessage.value =
          'Could not read prescription. Please retake the photo in good lighting.';
      Get.snackbar(
        'Could not read prescription',
        'Could not read prescription. Please retake the photo in good lighting.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } on VisionOcrException catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Vision OCR Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      _errorMessage.value = 'Processing failed: $e';
      Get.snackbar(
        'Processing Failed',
        'Unable to scan prescription right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Translate simplified text to Urdu on demand
  Future<void> translateSimplifiedTextToUrdu() async {
    if (_simplifiedText.value.trim().isEmpty) {
      Get.snackbar(
        'No Text Available',
        'There is no simplified text to translate yet.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_isTranslating.value) return;

    try {
      _isTranslating.value = true;
      _errorMessage.value = '';

      final translation = await _translator.translate(
        _simplifiedText.value,
        from: 'en',
        to: 'ur',
      );

      _translatedText.value = translation.text;
    } catch (e) {
      _errorMessage.value = 'Translation failed: $e';
      Get.snackbar(
        'Translation Failed',
        'Unable to translate the prescription summary right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isTranslating.value = false;
    }
  }

  /// Save prescription to Firebase
  Future<void> savePrescriptionToFirebase({
    required String doctorName,
    required String clinicName,
    String? diagnosis,
    String? notes,
    String? caregiverId,
  }) async {
    try {
      _isSaving.value = true;
      _errorMessage.value = '';

      final currentUser = _userController.user;

      // Create prescription ID
      final prescriptionId = _uuid.v4();

      // Create prescription model
      final prescription = PrescriptionModel(
        id: prescriptionId,
        patientId: currentUser.value.id,
        doctorId: '',
        caregiverId: caregiverId ?? '',
        doctorName: doctorName,
        clinicName: clinicName,
        datePrescribed: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 30)),
        diagnosis: diagnosis ?? '',
        medications: _extractedMedications,
        instructions: _getInstructions(),
        notes: notes ?? _extractedText.value,
        status: PrescriptionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: _prescriptionImageUrl.value,
        extractedText: _extractedText.value,
        simplifiedText: _simplifiedText.value,
      );

      // Save to Firebase
      await _prescriptionRepo.savePrescription(prescription);
      await _doseRepo.createDosesForPrescription(prescription);

      // Update local state
      _currentPrescription.value = prescription;

      // Navigate to success screen
      Get.offAllNamed(TRoutes.prescriptionSuccess, arguments: prescriptionId);

      Get.snackbar(
        'Success',
        'Prescription saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error saving prescription: $e');
      _errorMessage.value = 'Failed to save prescription: $e';
      Get.snackbar(
        'Error',
        'Failed to save prescription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSaving.value = false;
    }
  }

  /// Assign caregiver to prescription
  Future<void> assignCaregiverToPrescription({
    required String prescriptionId,
    required String caregiverId,
    required String caregiverName,
  }) async {
    try {
      await _prescriptionRepo.assignCaregiver(
        prescriptionId,
        caregiverId,
        caregiverName,
      );

      Get.snackbar(
        'Success',
        'Caregiver assigned successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      throw 'Failed to assign caregiver: $e';
    }
  }

  /// Get instructions list from medications
  List<String> _getInstructions() {
    return _extractedMedications
        .where((med) => med.instructions != null)
        .map((med) => med.instructions!)
        .toList();
  }

  String _buildMedicationSummary(List<Medication> medications, String rawText) {
    if (medications.isEmpty) {
      return rawText.trim().isEmpty
          ? 'Prescription scanned, but no medicines were extracted.'
          : 'Prescription scanned. Please review the extracted text and add medicines manually if needed.';
    }

    final buffer = StringBuffer('Prescription Summary:\n\n');
    for (var index = 0; index < medications.length; index++) {
      final medication = medications[index];
      buffer.writeln('${index + 1}. ${medication.name} ${medication.dosage}');
      buffer.writeln('   - Take ${medication.frequency}');
      if ((medication.instructions ?? '').trim().isNotEmpty) {
        buffer.writeln('   - ${medication.instructions}');
      }
      buffer.writeln('   - Continue for ${medication.duration}');
      if (index != medications.length - 1) buffer.writeln();
    }

    return buffer.toString();
  }

  void _showMedicineExtractionFailedSnackBar() {
    Get.snackbar(
      'Medicine Extraction Failed',
      'Prescription scanned but medicines could not be extracted. Please add medicines manually.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  /// Update medication timings
  void updateMedicationTiming(String medicationId, List<String> newTimings) {
    final index = _extractedMedications.indexWhere(
      (med) => med.id == medicationId,
    );
    if (index != -1) {
      final updatedMedication = _extractedMedications[index];
      // Create new medication with updated timings
      final newMedication = Medication(
        id: updatedMedication.id,
        name: updatedMedication.name,
        genericName: updatedMedication.genericName,
        dosage: updatedMedication.dosage,
        frequency: updatedMedication.frequency,
        duration: updatedMedication.duration,
        instructions: updatedMedication.instructions,
        startDate: updatedMedication.startDate,
        endDate: updatedMedication.endDate,
        timings: newTimings,
        withFood: updatedMedication.withFood,
        sideEffects: updatedMedication.sideEffects,
        notes: updatedMedication.notes,
      );

      _extractedMedications[index] = newMedication;
      _extractedMedications.refresh();
    }
  }

  /// Add custom medication
  void addCustomMedication(Medication medication) {
    _extractedMedications.add(medication);
    _extractedMedications.refresh();
  }

  /// Remove medication
  void removeMedication(String medicationId) {
    _extractedMedications.removeWhere((med) => med.id == medicationId);
    _extractedMedications.refresh();
  }

  /// Method to load prescription for editing
  void loadPrescriptionForEditing(PrescriptionModel prescription) {
    _isEditMode.value = true;
    _editingPrescription.value = prescription;

    // Set extracted data from the prescription
    _extractedText.value = prescription.extractedText ?? '';
    _simplifiedText.value = prescription.simplifiedText ?? '';
    _translatedText.value = '';
    extractedMedications.assignAll(prescription.medications);

    // Initialize medication timings
    for (var medication in prescription.medications) {
      updateMedicationTiming(medication.id, medication.timings);
    }
  }

  /// Method to update prescription
  Future<void> updatePrescriptionInFirebase({
    required String doctorName,
    required String clinicName,
    String? notes,
    String? caregiverId,
    DateTime? datePrescribed,
    DateTime? validUntil,
    String? diagnosis,
  }) async {
    try {
      _isSaving.value = true;

      // Create updated prescription
      final updatedPrescription = _editingPrescription.value.copyWith(
        doctorName: doctorName,
        clinicName: clinicName,
        notes: notes,
        caregiverId: caregiverId ?? '',
        datePrescribed:
            datePrescribed ?? _editingPrescription.value.datePrescribed,
        validUntil: validUntil,
        diagnosis: diagnosis ?? _editingPrescription.value.diagnosis,
        medications: extractedMedications,
        extractedText: extractedText,
        simplifiedText: simplifiedText,
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      await _prescriptionRepo.updatePrescription(updatedPrescription);
      await _doseRepo.createDosesForPrescription(updatedPrescription);

      _isSaving.value = false;

      // Show success message
      Get.snackbar(
        'Success',
        'Prescription updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back
      Get.back();
    } catch (e) {
      _isSaving.value = false;
      Get.snackbar(
        'Error',
        'Failed to update prescription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method to reset edit mode
  void resetEditMode() {
    _isEditMode.value = false;
    _editingPrescription.value = PrescriptionModel.empty();
    _extractedText.value = '';
    _simplifiedText.value = '';
    _translatedText.value = '';
    extractedMedications.clear();
    _isSaving.value = false;
    _isTranslating.value = false;
  }

  /// Clear all data
  void clearData() {
    _prescriptionImage.value = null;
    _extractedText.value = '';
    _simplifiedText.value = '';
    _translatedText.value = '';
    _errorMessage.value = '';
    _extractedMedications.clear();
    _currentPrescription.value = null;
    _isTranslating.value = false;
  }

  /// Retry processing
  Future<void> retryProcessing() async {
    if (_prescriptionImage.value != null) {
      await _processImage(_prescriptionImage.value!);
    }
  }
}
