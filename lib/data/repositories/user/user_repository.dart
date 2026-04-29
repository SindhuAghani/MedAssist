import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindheal/data/repositories/authentication/authentication_repository.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/utils/exceptions/firebase_exceptions.dart';
import 'package:mindheal/utils/exceptions/format_exceptions.dart';
import 'package:mindheal/utils/exceptions/platform_exceptions.dart';
import '../../../utils/constants/enums.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _firebaseStorage = FirebaseStorage.instance;


  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('Users');

  /// Get all users with a specific role (patients, doctors, caregivers)
  Future<List<UserModel>> getUsersByRole(AppRole role) async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: role.name)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Failed to fetch users by role: $e';
    }
  }

  /// Get all patients (users with patient role)
  Future<List<UserModel>> getAllPatients() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: AppRole.patient.name)
          .orderBy('firstName')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Failed to fetch patients: $e';
    }
  }

  /// Get all doctors
  Future<List<UserModel>> getAllDoctors() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: AppRole.doctor.name)
          .orderBy('firstName')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Failed to fetch doctors: $e';
    }
  }

  /// Get all caregivers
  Future<List<UserModel>> getAllCaregivers() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: AppRole.caregiver.name)
          .orderBy('firstName')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Failed to fetch caregivers: $e';
    }
  }

  /// Get user by ID
  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }
      throw 'User not found';
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Failed to fetch user: $e';
    }
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // First, search by first name (case-insensitive)
      final firstNameQuery = await _usersCollection
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThan: query + 'z')
          .get();

      // Search by last name
      final lastNameQuery = await _usersCollection
          .where('lastName', isGreaterThanOrEqualTo: query)
          .where('lastName', isLessThan: query + 'z')
          .get();

      // Search by email
      final emailQuery = await _usersCollection
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + 'z')
          .get();

      // Combine and deduplicate results
      final allDocs = [
        ...firstNameQuery.docs,
        ...lastNameQuery.docs,
        ...emailQuery.docs,
      ];

      final uniqueDocs = allDocs.fold<Map<String, QueryDocumentSnapshot>>(
        {},
            (map, doc) {
          map[doc.id] = doc;
          return map;
        },
      );

      return uniqueDocs.values
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to search users: $e';
    }
  }

  /// Get users by IDs (batch fetch)
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final List<UserModel> users = [];

      // Firestore has limit of 10 documents per 'in' query
      const batchSize = 10;
      for (var i = 0; i < userIds.length; i += batchSize) {
        final batchIds = userIds.sublist(
          i,
          i + batchSize > userIds.length ? userIds.length : i + batchSize,
        );

        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        users.addAll(
          querySnapshot.docs
              .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
              .toList(),
        );
      }

      return users;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch users by IDs: $e';
    }
  }

  /// Get active patients (with isProfileActive = true)
  Future<List<UserModel>> getActivePatients() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: AppRole.patient.name)
          .where('isProfileActive', isEqualTo: true)
          .orderBy('firstName')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch active patients: $e';
    }
  }

  /// Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to update user: $e';
    }
  }

  /// Get patient count (for statistics)
  Future<int> getPatientCount() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: AppRole.patient.name)
          .count()
          .get();

      return querySnapshot.count!;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to get patient count: $e';
    }
  }

  /// Stream all patients for real-time updates
  Stream<List<UserModel>> streamAllPatients() {
    return _usersCollection
        .where('role', isEqualTo: AppRole.patient.name)
        .orderBy('firstName')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get users with pagination
  Future<List<UserModel>> getPatientsWithPagination({
    required int limit,
    required String? lastDocumentId,
  }) async {
    try {
      Query query = _usersCollection
          .where('role', isEqualTo: AppRole.patient.name)
          .orderBy('firstName')
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _usersCollection.doc(lastDocumentId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch patients with pagination: $e';
    }
  }

  /// Function to remove user data from Firestore.
  Future<void> removeUserRecord(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Update any field in specific Users Collection
  Future<void> updateSingleField(Map<String, dynamic> json) async {
    try {
      await _usersCollection.doc(AuthenticationRepository.instance.getUserID).update(json);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong!';
    }
  }


  /// Upload any Image
  Future<String> uploadImage(String path, XFile image) async {
    try {
      final ref = _firebaseStorage.ref(path).child(image.name);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong try again';
    }
  }

  /// Function to fetch user details based on user ID.
  Future<UserModel> fetchUserDetails() async {
    try {
      final documentSnapshot = await _usersCollection.doc(AuthenticationRepository.instance.getUserID).get();
      if (documentSnapshot.exists) {
        return UserModel.fromDocSnapshot(documentSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        return UserModel.empty();
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Function to save user data to Firestore.
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}