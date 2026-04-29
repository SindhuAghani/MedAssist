import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindheal/data/repositories/prescription/prescription_repository.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/routes/routes.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:translator/translator.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:uuid/uuid.dart';

class PrescriptionReaderController extends GetxController {
  // Dependencies
  final PrescriptionRepository _prescriptionRepo = Get.put(PrescriptionRepository());
  final UserController _userController = Get.put(UserController());

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
  final Rx<PrescriptionModel> _editingPrescription = PrescriptionModel.empty().obs;
  final RxBool _isEditMode = false.obs;
  final Rx<PrescriptionModel?> _currentPrescription = Rx<PrescriptionModel?>(null);
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
    _translatedText.value = '';
    _extractedMedications.clear();

    try {
      // Step 1: Upload image to Firebase Storage
      final imageUrl = await _uploadImageToStorage(imageFile);
      _prescriptionImageUrl.value = imageUrl;

      // Step 2: Extract text using OCR (mock for now)
      await _extractTextFromImage(imageFile);

      // Step 3: Parse medications from extracted text
      await _parseMedicationsFromText();

      // Step 4: Simplify text using AI (mock for now)
      await _simplifyMedicalText();

      // Step 5: Navigate to preview screen
      if (_extractedText.isNotEmpty) {
        Get.toNamed(
            TRoutes.prescriptionResults,
            arguments: {
              'extractedText': _extractedText.value,
              'simplifiedText': _simplifiedText.value,
              'medications': _extractedMedications,
              'imageUrl': imageUrl,
            }
        );
      }

    } catch (e) {
      _errorMessage.value = 'Processing failed: $e';
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Upload image to Firebase Storage
  Future<String> _uploadImageToStorage(File imageFile) async {
    try {

      // Create a unique prescription ID
      final prescriptionId = _uuid.v4();

      // Upload to Firebase Storage
      final imageUrl = await _prescriptionRepo.uploadPrescriptionImage(
          imageFile.path,
          prescriptionId
      );

      return imageUrl;
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  /// Extract text from image (mock OCR - replace with actual OCR service)
  Future<void> _extractTextFromImage(File imageFile) async {
    try {
      // TODO: Replace with actual OCR integration (Google ML Kit, Tesseract, etc.)
      await Future.delayed(const Duration(seconds: 2));

      // Mock extracted text
      _extractedText.value = '''
    
      MEDICATIONS:
      1. Amoxicillin 500mg
        - Dosage: 1 tablet
        - Frequency: Every 8 hours
        - Duration: 7 days
        - Instructions: Take with food
        
      2. Ibuprofen 400mg
        - Dosage: 1 tablet
        - Frequency: Every 6 hours as needed
        - Duration: 5 days
        - Instructions: Take with plenty of water
        
      3. Guaifenesin 600mg
        - Dosage: 1 tablet
        - Frequency: Twice daily
        - Duration: 7 days
        - Instructions: Drink plenty of fluids
        
      FOLLOW-UP: Return in 7 days if symptoms persist
      ''';

    } catch (e) {
      throw 'OCR extraction failed: $e';
    }
  }

  /// Parse medications from extracted text
  Future<void> _parseMedicationsFromText() async {
    try {
      // TODO: Implement actual medication parsing logic
      // For now, create mock medications based on extracted text

      final medications = <Medication>[
        Medication(
          id: _uuid.v4(),
          name: 'Amoxicillin',
          genericName: 'Amoxicillin',
          dosage: '500mg',
          frequency: 'Every 8 hours',
          duration: '7 days',
          instructions: 'Take with food',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          timings: ['08:00', '16:00', '00:00'],
          withFood: true,
          sideEffects: ['Nausea', 'Diarrhea'],
          notes: 'Complete full course even if feeling better',
        ),
        Medication(
          id: _uuid.v4(),
          name: 'Ibuprofen',
          genericName: 'Ibuprofen',
          dosage: '400mg',
          frequency: 'Every 6 hours as needed',
          duration: '5 days',
          instructions: 'Take with plenty of water',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 5)),
          timings: ['06:00', '12:00', '18:00', '00:00'],
          withFood: false,
          sideEffects: ['Stomach upset', 'Dizziness'],
          notes: 'Take only when needed for pain',
        ),
      ];

      _extractedMedications.assignAll(medications);

    } catch (e) {
      throw 'Failed to parse medications: $e';
    }
  }

  /// Simplify medical text using AI
  Future<void> _simplifyMedicalText() async {
    try {
      // TODO: Integrate with Gemini API for AI simplification
      await Future.delayed(const Duration(seconds: 1));

      _simplifiedText.value = '''
      Prescription Summary:
      
      1. Amoxicillin 500mg
         - Take 1 tablet every 8 hours (3 times a day)
         - Take with food
         - Continue for 7 days
         - Complete all tablets even if you feel better
         
      2. Ibuprofen 400mg
         - Take 1 tablet every 6 hours only when needed for pain
         - Take with plenty of water
         - Use for up to 5 days
         
      Important: Return to doctor in 7 days if symptoms don't improve.
      ''';

    } catch (e) {
      throw 'AI simplification failed: $e';
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

      // Update local state
      _currentPrescription.value = prescription;

      // Navigate to success screen
      Get.offAllNamed(
        TRoutes.prescriptionSuccess,
        arguments: prescriptionId,
      );

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

  /// Update medication timings
  void updateMedicationTiming(String medicationId, List<String> newTimings) {
    final index = _extractedMedications.indexWhere((med) => med.id == medicationId);
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
        datePrescribed: datePrescribed ?? _editingPrescription.value.datePrescribed,
        validUntil: validUntil,
        diagnosis: diagnosis ?? _editingPrescription.value.diagnosis,
        medications: extractedMedications,
        extractedText: extractedText,
        simplifiedText: simplifiedText,
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      await _prescriptionRepo.updatePrescription(updatedPrescription);

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
