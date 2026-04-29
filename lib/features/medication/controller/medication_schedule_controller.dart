import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/prescription/prescription_repository.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:table_calendar/table_calendar.dart';

class MedicationScheduleController extends GetxController {
  // Dependencies
  final PrescriptionRepository _prescriptionRepo = Get.put(PrescriptionRepository());

  // Rx variables
  final Rx<PrescriptionModel?> _prescription = Rx<PrescriptionModel?>(null);
  final RxList<String> _takenMedications = <String>[].obs;
  final Rx<DateTime> _selectedDay = Rx<DateTime>(DateTime.now());
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  PrescriptionModel? get prescription => _prescription.value;
  DateTime get selectedDay => _selectedDay.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  String get selectedDayFormatted {
    return '${_selectedDay.value.day}/${_selectedDay.value.month}/${_selectedDay.value.year}';
  }

  String get selectedDayWeekday {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[_selectedDay.value.weekday - 1];
  }

  // Statistics
  int get totalMedications {
    return _prescription.value?.medications.length ?? 0;
  }

  int get takenMedications => _takenMedications.length;

  int get missedMedications {
    if (_prescription.value == null) return 0;

    final today = DateTime.now();
    if (!isSameDay(_selectedDay.value, today)) return 0;

    int missed = 0;
    for (var medication in _prescription.value!.medications) {
      if (isMedicationMissed(medication) && !_takenMedications.contains(medication.id)) {
        missed++;
      }
    }
    return missed;
  }

  int get pendingMedications {
    if (_prescription.value == null) return 0;

    final today = DateTime.now();
    if (!isSameDay(_selectedDay.value, today)) return 0;

    int pending = 0;
    for (var medication in _prescription.value!.medications) {
      if (!isMedicationMissed(medication) &&
          !_takenMedications.contains(medication.id)) {
        pending++;
      }
    }
    return pending;
  }

  /// Load prescription schedule
  Future<void> loadPrescriptionSchedule(String prescriptionId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final prescription = await _prescriptionRepo.getPrescriptionById(prescriptionId);
      _prescription.value = prescription;

      // Load taken medications from local storage
      _loadTakenMedications(prescriptionId);

    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load medication schedule: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load taken medications from local storage
  void _loadTakenMedications(String prescriptionId) {
    // In a real app, you would load from local database or Firestore
    // For now, we'll use a mock list
    _takenMedications.value = [];
  }

  /// Get medications for selected day
  List<Medication> getMedicationsForSelectedDay(PrescriptionModel prescription) {
    if (_selectedDay.value.isBefore(prescription.datePrescribed)) {
      return [];
    }

    return prescription.medications.where((medication) {
      // Check if medication is active on selected day
      if (_selectedDay.value.isBefore(medication.startDate)) return false;
      if (medication.endDate != null &&
          _selectedDay.value.isAfter(medication.endDate!)) return false;

      return true;
    }).toList();
  }

  /// Check if medication is taken
  bool isMedicationTaken(String medicationId) {
    return _takenMedications.contains(medicationId);
  }

  /// Check if medication is missed (time has passed)
  bool isMedicationMissed(Medication medication) {
    final now = DateTime.now();
    if (!isSameDay(_selectedDay.value, now)) return false;

    for (var time in medication.timings) {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        final medicationTime = DateTime(
            now.year, now.month, now.day, hour, minute
        );

        if (medicationTime.isBefore(now)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Mark medication as taken
  void markMedicationAsTaken(String medicationId) {
    if (!_takenMedications.contains(medicationId)) {
      _takenMedications.add(medicationId);
      _takenMedications.refresh();

      // In a real app, save to local database or Firestore

      Get.snackbar(
        'Success',
        'Medication marked as taken',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  /// Mark all medications as taken for today
  void markAllMedicationsAsTaken() {
    if (_prescription.value == null) return;

    final medications = getMedicationsForSelectedDay(_prescription.value!);
    for (var medication in medications) {
      if (!_takenMedications.contains(medication.id)) {
        _takenMedications.add(medication.id);
      }
    }
    _takenMedications.refresh();

    Get.snackbar(
      'Success',
      'All medications marked as taken',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// Go to previous day
  void previousDay() {
    _selectedDay.value = _selectedDay.value.subtract(const Duration(days: 1));
    _takenMedications.clear(); // Clear taken medications for new day
  }

  /// Go to next day
  void nextDay() {
    _selectedDay.value = _selectedDay.value.add(const Duration(days: 1));
    _takenMedications.clear(); // Clear taken medications for new day
  }

  /// Go to today
  void goToToday() {
    _selectedDay.value = DateTime.now();
    _takenMedications.clear();
  }

  /// Select specific date
  void selectDate(DateTime date) {
    _selectedDay.value = date;
    _takenMedications.clear();
  }

  /// Refresh data
  Future<void> refresh() async {
    if (_prescription.value != null) {
      await loadPrescriptionSchedule(_prescription.value!.id);
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage.value = '';
  }
}