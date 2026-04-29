import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mindheal/utils/formatters/formatter.dart';
import '../../../utils/constants/enums.dart';

/// Model class representing user data.
class UserModel {
  final String id;
  String firstName;
  String lastName;
  String userName;
  String email;
  String phoneNumber;
  String profilePicture;
  AppRole role;

  DateTime? createdAt;
  DateTime? updatedAt;

  bool isProfileActive;
  bool isEmailVerified;
  VerificationStatus verificationStatus;

  String deviceToken;

  // Relationships (for quick access)
  List<String>? doctorIds; // For patients: list of their doctors
  List<String>? patientIds; // For doctors/caregivers: list of their patients
  List<String>? caregiverIds; // For patients: list of their caregivers

  /// Constructor for UserModel.
  UserModel({
    required this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.userName = '',
    this.phoneNumber = '',
    this.profilePicture = '',
    this.role = AppRole.patient,
    this.createdAt,
    this.updatedAt,
    this.deviceToken = '',
    required this.isEmailVerified,
    required this.isProfileActive,
    this.verificationStatus = VerificationStatus.pending,
    this.doctorIds,
    this.patientIds,
    this.caregiverIds,
  });

  /// Helper methods
  String get fullName => '$firstName $lastName'.trim();

  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  String get formattedDate => TFormatter.formatDateAndTime(createdAt);

  String get formattedUpdatedAtDate => TFormatter.formatDateAndTime(updatedAt);

  /// Get initials for avatar
  String get initials {
    if (firstName.isEmpty && lastName.isEmpty) return 'U';
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return (firstInitial + lastInitial).toUpperCase();
  }

  /// Check if user has complete profile
  bool get hasCompleteProfile {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        phoneNumber.isNotEmpty;
  }

  /// Check if user is verified
  bool get isVerified => verificationStatus == VerificationStatus.approved;

  /// Get user type as string
  String get roleString {
    switch (role) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.doctor:
        return 'Doctor';
      case AppRole.patient:
        return 'Patient';
      case AppRole.caregiver:
        return 'Caregiver';
      default:
        return 'User';
    }
  }

  /// Static function to split full name into first and last name.
  static List<String> nameParts(fullName) => fullName.split(" ");

  /// Static function to generate a username from the full name.
  static String generateUsername(fullName) {
    List<String> nameParts = fullName.split(" ");
    String firstName = nameParts[0].toLowerCase();
    String lastName = nameParts.length > 1 ? nameParts[1].toLowerCase() : "";

    String camelCaseUsername = "$firstName$lastName"; // Combine first and last name
    String usernameWithPrefix = "cwt_$camelCaseUsername"; // Add "cwt_" prefix
    return usernameWithPrefix;
  }

  /// Static function to create an empty user model.
  static UserModel empty() => UserModel(
    id: '',
    email: '',
    isEmailVerified: false,
    isProfileActive: false,
  );

  /// Convert model to JSON structure for storing data in Firebase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'userName': userName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'role': role.name,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': updatedAt ?? DateTime.now(),
      'deviceToken': deviceToken,
      'isEmailVerified': isEmailVerified,
      'isProfileActive': isProfileActive,
      'verificationStatus': verificationStatus.name,
      'doctorIds': doctorIds,
      'patientIds': patientIds,
      'caregiverIds': caregiverIds,
    };
  }

  // Factory method to create UserModel from Firestore document snapshot
  factory UserModel.fromDocSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel.fromJson(doc.id, data);
  }

  // Static method to create a list of UserModel from QuerySnapshot (for retrieving multiple users)
  static UserModel fromQuerySnapshot(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(doc.id, data);
  }

  /// Factory method to create a UserModel from a Firebase document snapshot.
  factory UserModel.fromJson(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      userName: data['userName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profilePicture: data['profilePicture'] ?? '',
      role: _mapRoleStringToEnum(data['role'] ?? 'patient'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceToken: data['deviceToken'] ?? '',
      isEmailVerified: data['isEmailVerified'] ?? false,
      isProfileActive: data['isProfileActive'] ?? false,
      verificationStatus: _mapVerificationStringToEnum(data['verificationStatus'] ?? 'pending'),
      doctorIds: data['doctorIds'] != null
          ? List<String>.from(data['doctorIds'])
          : [],
      patientIds: data['patientIds'] != null
          ? List<String>.from(data['patientIds'])
          : [],
      caregiverIds: data['caregiverIds'] != null
          ? List<String>.from(data['caregiverIds'])
          : [],
    );
  }

  /// Copy with method for easy updates
  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? userName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    AppRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isProfileActive,
    bool? isEmailVerified,
    VerificationStatus? verificationStatus,
    String? deviceToken,
    List<String>? doctorIds,
    List<String>? patientIds,
    List<String>? caregiverIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isProfileActive: isProfileActive ?? this.isProfileActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      deviceToken: deviceToken ?? this.deviceToken,
      doctorIds: doctorIds ?? this.doctorIds,
      patientIds: patientIds ?? this.patientIds,
      caregiverIds: caregiverIds ?? this.caregiverIds,
    );
  }

  /// Add doctor to patient's doctor list
  UserModel addDoctor(String doctorId) {
    final updatedDoctorIds = List<String>.from(doctorIds ?? []);
    if (!updatedDoctorIds.contains(doctorId)) {
      updatedDoctorIds.add(doctorId);
    }
    return copyWith(doctorIds: updatedDoctorIds);
  }

  /// Add patient to doctor's/caregiver's patient list
  UserModel addPatient(String patientId) {
    final updatedPatientIds = List<String>.from(patientIds ?? []);
    if (!updatedPatientIds.contains(patientId)) {
      updatedPatientIds.add(patientId);
    }
    return copyWith(patientIds: updatedPatientIds);
  }

  /// Add caregiver to patient's caregiver list
  UserModel addCaregiver(String caregiverId) {
    final updatedCaregiverIds = List<String>.from(caregiverIds ?? []);
    if (!updatedCaregiverIds.contains(caregiverId)) {
      updatedCaregiverIds.add(caregiverId);
    }
    return copyWith(caregiverIds: updatedCaregiverIds);
  }

  /// Remove relationship
  UserModel removeDoctor(String doctorId) {
    final updatedDoctorIds = List<String>.from(doctorIds ?? []);
    updatedDoctorIds.remove(doctorId);
    return copyWith(doctorIds: updatedDoctorIds);
  }

  UserModel removePatient(String patientId) {
    final updatedPatientIds = List<String>.from(patientIds ?? []);
    updatedPatientIds.remove(patientId);
    return copyWith(patientIds: updatedPatientIds);
  }

  UserModel removeCaregiver(String caregiverId) {
    final updatedCaregiverIds = List<String>.from(caregiverIds ?? []);
    updatedCaregiverIds.remove(caregiverId);
    return copyWith(caregiverIds: updatedCaregiverIds);
  }

  // Utility to map a role string to the Roles enum
  static AppRole _mapRoleStringToEnum(String role) {
    switch (role) {
      case 'admin':
        return AppRole.admin;
      case 'doctor':
        return AppRole.doctor;
      case 'patient':
        return AppRole.patient;
      case 'caregiver':
        return AppRole.caregiver;
      default:
        return AppRole.patient;
    }
  }

  // Utility to map verification status string to enum
  static VerificationStatus _mapVerificationStringToEnum(String verification) {
    switch (verification) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'submitted':
        return VerificationStatus.submitted;
      case 'underReview':
        return VerificationStatus.underReview;
      default:
        return VerificationStatus.unknown;
    }
  }

  /// Get display color based on role
  static Color getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return Colors.red;
      case AppRole.doctor:
        return Colors.blue;
      case AppRole.patient:
        return Colors.green;
      case AppRole.caregiver:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get icon based on role
  static IconData getRoleIcon(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return Icons.admin_panel_settings;
      case AppRole.doctor:
        return Icons.local_hospital;
      case AppRole.patient:
        return Icons.person;
      case AppRole.caregiver:
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }

  /// Validate user data
  static List<String> validateUserData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['email'] == null || (data['email'] as String).isEmpty) {
      errors.add('Email is required');
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(data['email'])) {
      errors.add('Invalid email format');
    }

    if (data['firstName'] == null || (data['firstName'] as String).isEmpty) {
      errors.add('First name is required');
    }

    if (data['phoneNumber'] == null || (data['phoneNumber'] as String).isEmpty) {
      errors.add('Phone number is required');
    }

    return errors;
  }

  /// Compare two users for equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  /// String representation for debugging
  @override
  String toString() {
    return 'UserModel(id: $id, name: $fullName, email: $email, role: $role)';
  }
}