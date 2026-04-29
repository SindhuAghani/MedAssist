import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/exceptions/firebase_exceptions.dart';
import 'package:mindheal/utils/exceptions/format_exceptions.dart';
import '../../../utils/constants/enums.dart';

class PrescriptionRepository extends GetxController {
  static PrescriptionRepository get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _prescriptionsCollection => _firestore.collection('Prescriptions');
  CollectionReference get _usersCollection => _firestore.collection('Users');

  /// Save prescription to Firestore
  Future<void> savePrescription(PrescriptionModel prescription) async {
    try {
      await _prescriptionsCollection.doc(prescription.id).set(prescription.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  /// update prescription to Firestore
  Future<void> updatePrescription(PrescriptionModel prescription) async {
    try {
      await _prescriptionsCollection.doc(prescription.id).update(prescription.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  /// Upload prescription image to Firebase Storage
  Future<String> uploadPrescriptionImage(String filePath, String prescriptionId) async {
    try {
      final Reference ref = _storage
          .ref('prescriptions/$prescriptionId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to upload image';
    }
  }

  /// Get prescriptions for a specific patient
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    try {
      final querySnapshot = await _prescriptionsCollection
          .where('patientId', isEqualTo: patientId)
          .orderBy('datePrescribed', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PrescriptionModel.fromDocument(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch prescriptions';
    }
  }

  /// Get prescriptions managed by a caregiver
  Future<List<PrescriptionModel>> getCaregiverPrescriptions(String caregiverId) async {
    try {
      final querySnapshot = await _prescriptionsCollection
          .where('caregiverId', isEqualTo: caregiverId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PrescriptionModel.fromDocument(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch caregiver prescriptions';
    }
  }

  /// Get all patients managed by a caregiver
  Future<List<UserModel>> getCaregiverPatients(String caregiverId) async {
    try {
      // First get all prescriptions where this caregiver is assigned
      final prescriptionsSnapshot = await _prescriptionsCollection
          .where('caregiverId', isEqualTo: caregiverId)
          .get();

      // Extract unique patient IDs
      final Set<String> patientIds = {};
      for (var doc in prescriptionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        patientIds.add(data['patientId']);
      }

      // Fetch user details for each patient
      final List<UserModel> patients = [];
      for (var patientId in patientIds) {
        final userDoc = await _usersCollection.doc(patientId).get();
        if (userDoc.exists) {
          patients.add(UserModel.fromJson(userDoc.id,userDoc.data() as Map<String, dynamic>));
        }
      }

      return patients;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch patients';
    }
  }

  /// Update prescription status
  Future<void> updatePrescriptionStatus(
      String prescriptionId,
      PrescriptionStatus status
      ) async {
    try {
      await _prescriptionsCollection.doc(prescriptionId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to update prescription';
    }
  }

  /// Add new medication to prescription
  Future<void> addMedication(
      String prescriptionId,
      Medication medication
      ) async {
    try {
      await _prescriptionsCollection.doc(prescriptionId).update({
        'medications': FieldValue.arrayUnion([medication.toJson()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to add medication';
    }
  }

  /// Delete prescription
  Future<void> deletePrescription(String prescriptionId) async {
    try {
      await _prescriptionsCollection.doc(prescriptionId).delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to delete prescription';
    }
  }

  /// Stream prescriptions for real-time updates
  Stream<List<PrescriptionModel>> streamPatientPrescriptions(String patientId) {
    return _prescriptionsCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('datePrescribed', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PrescriptionModel.fromDocument(doc))
        .toList());
  }

  /// Get prescription by ID
  Future<PrescriptionModel> getPrescriptionById(String prescriptionId) async {
    try {
      final doc = await _prescriptionsCollection.doc(prescriptionId).get();
      if (doc.exists) {
        return PrescriptionModel.fromDocument(doc);
      }
      throw 'Prescription not found';
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch prescription';
    }
  }

  /// Assign caregiver to prescription
  Future<void> assignCaregiver(
      String prescriptionId,
      String caregiverId,
      String caregiverName
      ) async {
    try {
      await _prescriptionsCollection.doc(prescriptionId).update({
        'caregiverId': caregiverId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to assign caregiver';
    }
  }
}