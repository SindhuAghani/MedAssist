import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/prescription/models/prescription_model.dart';
import '../../services/notifications/notification_model.dart';
import '../../services/reminders/medication_dose_model.dart';
import '../notifications/notification_repository.dart';

class MedicationDoseRepository extends GetxController {
  static MedicationDoseRepository get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _dosesCollection =>
      _firestore.collection('MedicationDoses');

  Future<void> createDosesForPrescription(PrescriptionModel prescription) async {
    await deleteDosesForPrescription(prescription.id);

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final medication in prescription.medications) {
      for (final scheduledAt in _expandMedicationSchedule(medication)) {
        if (scheduledAt.isBefore(now)) continue;

        final id = _uuid.v4();
        final dose = MedicationDoseModel(
          id: id,
          prescriptionId: prescription.id,
          medicationId: medication.id,
          patientId: prescription.patientId,
          caregiverId: prescription.caregiverId,
          medicationName: medication.name,
          dosage: medication.dosage,
          frequency: medication.frequency,
          instructions: medication.instructions ?? '',
          scheduledAt: scheduledAt,
          createdAt: now,
          updatedAt: now,
        );

        batch.set(_dosesCollection.doc(id), dose.toJson());
      }
    }

    await batch.commit();
  }

  Future<void> deleteDosesForPrescription(String prescriptionId) async {
    final existing = await _dosesCollection
        .where('prescriptionId', isEqualTo: prescriptionId)
        .get();
    if (existing.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<MedicationDoseModel>> streamPatientDosesForDay(String patientId, DateTime day) {
    final range = _dayRange(day);
    return _dosesCollection
        .where('patientId', isEqualTo: patientId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(range.end))
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(MedicationDoseModel.fromDocSnapshot).toList());
  }

  Stream<List<MedicationDoseModel>> streamCaregiverDosesForDay(String caregiverId, DateTime day) {
    final range = _dayRange(day);
    return _dosesCollection
        .where('caregiverId', isEqualTo: caregiverId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(range.end))
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(MedicationDoseModel.fromDocSnapshot).toList());
  }

  Future<void> markDoseTaken(String doseId) async {
    await _updateDoseStatus(doseId, MedicationDoseStatus.taken);
  }

  Future<void> skipDose(String doseId) async {
    await _updateDoseStatus(doseId, MedicationDoseStatus.skipped);
  }

  Future<void> snoozeDose(String doseId, {Duration duration = const Duration(minutes: 10)}) async {
    await _dosesCollection.doc(doseId).update({
      'status': MedicationDoseStatus.snoozed.name,
      'scheduledAt': Timestamp.fromDate(DateTime.now().add(duration)),
      'updatedAt': FieldValue.serverTimestamp(),
      'reminderSentAt': null,
      'escalationSentAt': null,
    });
  }

  Future<void> sendManualReminderToPatient(MedicationDoseModel dose, String caregiverId) async {
    await NotificationRepository.instance.addItem(NotificationModel(
      id: '',
      title: 'Medication reminder',
      body: 'Please take ${dose.medicationName} ${dose.dosage}.',
      senderId: caregiverId,
      recipientIds: [dose.patientId],
      type: 'caregiver_dose_reminder',
      createdAt: DateTime.now(),
      seenBy: {dose.patientId: false},
      route: '/patient-medications',
      routeId: dose.id,
      isBroadcast: false,
    ));

    await _dosesCollection.doc(dose.id).update({
      'manualReminderCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateDoseStatus(String doseId, MedicationDoseStatus status) async {
    await _dosesCollection.doc(doseId).update({
      'status': status.name,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<DateTime> _expandMedicationSchedule(Medication medication) {
    final dates = <DateTime>[];
    final start = DateTime(
      medication.startDate.year,
      medication.startDate.month,
      medication.startDate.day,
    );
    final endSource = medication.endDate ?? medication.startDate.add(const Duration(days: 30));
    final end = DateTime(endSource.year, endSource.month, endSource.day);

    for (var day = start; day.isBefore(end); day = day.add(const Duration(days: 1))) {
      for (final time in medication.timings) {
        final parts = time.split(':');
        if (parts.length != 2) continue;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        dates.add(DateTime(day.year, day.month, day.day, hour, minute));
      }
    }

    return dates;
  }

  _DayRange _dayRange(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return _DayRange(start, start.add(const Duration(days: 1)));
  }
}

class _DayRange {
  final DateTime start;
  final DateTime end;

  const _DayRange(this.start, this.end);
}
