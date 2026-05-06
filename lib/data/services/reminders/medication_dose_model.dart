import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicationDoseStatus { pending, taken, skipped, snoozed, missed }

class MedicationDoseModel {
  String id;
  final String prescriptionId;
  final String medicationId;
  final String patientId;
  final String caregiverId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String instructions;
  final DateTime scheduledAt;
  final MedicationDoseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderSentAt;
  final DateTime? escalationSentAt;
  final DateTime? respondedAt;
  final int manualReminderCount;

  MedicationDoseModel({
    required this.id,
    required this.prescriptionId,
    required this.medicationId,
    required this.patientId,
    required this.caregiverId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.instructions,
    required this.scheduledAt,
    this.status = MedicationDoseStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.reminderSentAt,
    this.escalationSentAt,
    this.respondedAt,
    this.manualReminderCount = 0,
  });

  bool get hasCaregiver => caregiverId.trim().isNotEmpty;
  bool get isPending => status == MedicationDoseStatus.pending || status == MedicationDoseStatus.snoozed;
  bool get isAnswered => status == MedicationDoseStatus.taken || status == MedicationDoseStatus.skipped;

  factory MedicationDoseModel.fromJson(String id, Map<String, dynamic> json) {
    return MedicationDoseModel(
      id: id,
      prescriptionId: json['prescriptionId'] ?? '',
      medicationId: json['medicationId'] ?? '',
      patientId: json['patientId'] ?? '',
      caregiverId: json['caregiverId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      instructions: json['instructions'] ?? '',
      scheduledAt: _dateFromJson(json['scheduledAt']) ?? DateTime.now(),
      status: MedicationDoseStatus.values.firstWhere(
        (status) => status.name == (json['status'] ?? MedicationDoseStatus.pending.name),
        orElse: () => MedicationDoseStatus.pending,
      ),
      createdAt: _dateFromJson(json['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromJson(json['updatedAt']) ?? DateTime.now(),
      reminderSentAt: _dateFromJson(json['reminderSentAt']),
      escalationSentAt: _dateFromJson(json['escalationSentAt']),
      respondedAt: _dateFromJson(json['respondedAt']),
      manualReminderCount: json['manualReminderCount'] ?? 0,
    );
  }

  factory MedicationDoseModel.fromDocSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MedicationDoseModel.fromJson(doc.id, doc.data() ?? {});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prescriptionId': prescriptionId,
      'medicationId': medicationId,
      'patientId': patientId,
      'caregiverId': caregiverId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reminderSentAt': reminderSentAt == null ? null : Timestamp.fromDate(reminderSentAt!),
      'escalationSentAt': escalationSentAt == null ? null : Timestamp.fromDate(escalationSentAt!),
      'respondedAt': respondedAt == null ? null : Timestamp.fromDate(respondedAt!),
      'manualReminderCount': manualReminderCount,
    };
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
