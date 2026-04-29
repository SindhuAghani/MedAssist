import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/formatters/formatter.dart';

class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String caregiverId; // Who's managing this prescription
  final String doctorName;
  final String clinicName;
  final DateTime datePrescribed;
  final DateTime? validUntil;
  final String diagnosis;
  final List<Medication> medications;
  final List<String>? instructions;
  final String? notes;
  final PrescriptionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl; // Scanned prescription image
  final String? extractedText; // OCR extracted text
  final String? simplifiedText; // AI simplified version

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.caregiverId = '',
    required this.doctorName,
    this.clinicName = '',
    required this.datePrescribed,
    this.validUntil,
    this.diagnosis = '',
    required this.medications,
    this.instructions,
    this.notes,
    this.status = PrescriptionStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.extractedText,
    this.simplifiedText,
  });

  // Helper getters
  String get formattedDate => TFormatter.formatDate(datePrescribed);
  String get formattedValidUntil => validUntil != null
      ? TFormatter.formatDate(validUntil!)
      : 'N/A';
  bool get isExpired => validUntil != null && validUntil!.isBefore(DateTime.now());
  int get remainingDays => validUntil != null
      ? validUntil!.difference(DateTime.now()).inDays
      : -1;

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'caregiverId': caregiverId,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'datePrescribed': datePrescribed,
      'validUntil': validUntil,
      'diagnosis': diagnosis,
      'medications': medications.map((med) => med.toJson()).toList(),
      'instructions': instructions,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'simplifiedText': simplifiedText,
    };
  }

  // Factory method from Firestore document
  factory PrescriptionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrescriptionModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      clinicName: data['clinicName'] ?? '',
      datePrescribed: (data['datePrescribed'] as Timestamp).toDate(),
      validUntil: data['validUntil'] != null
          ? (data['validUntil'] as Timestamp).toDate()
          : null,
      diagnosis: data['diagnosis'] ?? '',
      medications: (data['medications'] as List<dynamic>)
          .map((med) => Medication.fromJson(med as Map<String, dynamic>))
          .toList(),
      instructions: List<String>.from(data['instructions'] ?? []),
      notes: data['notes'],
      status: PrescriptionStatus.values.firstWhere(
            (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => PrescriptionStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      extractedText: data['extractedText'],
      simplifiedText: data['simplifiedText'],
    );
  }

  // Empty prescription
  static PrescriptionModel empty() => PrescriptionModel(
    id: '',
    patientId: '',
    doctorId: '',
    doctorName: '',
    datePrescribed: DateTime.now(),
    medications: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Copy with method for updates
  PrescriptionModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? caregiverId,
    String? doctorName,
    String? clinicName,
    DateTime? datePrescribed,
    DateTime? validUntil,
    String? diagnosis,
    List<Medication>? medications,
    List<String>? instructions,
    String? notes,
    PrescriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? extractedText,
    String? simplifiedText,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      caregiverId: caregiverId ?? this.caregiverId,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      datePrescribed: datePrescribed ?? this.datePrescribed,
      validUntil: validUntil ?? this.validUntil,
      diagnosis: diagnosis ?? this.diagnosis,
      medications: medications ?? this.medications,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      extractedText: extractedText ?? this.extractedText,
      simplifiedText: simplifiedText ?? this.simplifiedText,
    );
  }
}

// Medication sub-model
class Medication {
  final String id;
  final String name;
  final String genericName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> timings; // Specific times for reminders
  final bool withFood;
  final List<String>? sideEffects;
  final String? notes;

  Medication({
    required this.id,
    required this.name,
    this.genericName = '',
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    required this.startDate,
    this.endDate,
    required this.timings,
    this.withFood = false,
    this.sideEffects,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'startDate': startDate,
      'endDate': endDate,
      'timings': timings,
      'withFood': withFood,
      'sideEffects': sideEffects,
      'notes': notes,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      genericName: json['genericName'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      instructions: json['instructions'],
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      timings: List<String>.from(json['timings'] ?? []),
      withFood: json['withFood'] ?? false,
      sideEffects: json['sideEffects'] != null
          ? List<String>.from(json['sideEffects'])
          : null,
      notes: json['notes'],
    );
  }
}

