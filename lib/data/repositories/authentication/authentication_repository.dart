import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mindheal/features/authentication/screens/login/login.dart';
import 'package:mindheal/features/caregiver/controller/caregiver_controller.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/personalization/controllers/notifcation_controller.dart';
import 'package:mindheal/features/prescription/controller/prescription_medication_controller.dart';
import 'package:mindheal/features/test_reports/controller/test_report_analytics_controller.dart';
import 'package:mindheal/features/test_reports/controller/test_report_detail_controller.dart';
import 'package:mindheal/features/test_reports/controller/test_report_form_controller.dart';
import 'package:mindheal/features/test_reports/controller/test_report_list_controller.dart';
import 'package:mindheal/utils/constants/enums.dart';

import '../../../features/Home/home_page.dart';
import '../../../features/authentication/screens/onboarding/onboarding.dart';
import '../../../features/authentication/screens/signup/verify_email.dart';
import '../../../features/caregiver/screens/caregiver_dashboard_Screen.dart';
import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../../utils/local_storage/storage_utility.dart';
import '../user/user_repository.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  late final Rx<User?> _firebaseUser;
  var phoneNo = ''.obs;
  var phoneNoVerificationId = ''.obs;
  var isPhoneAutoVerified = false;
  final _auth = FirebaseAuth.instance;
  int? _resendToken;
  int failedAttempts = 0;

  /// Getters
  User? get firebaseUser => _firebaseUser.value;

  String get getUserID => _firebaseUser.value?.uid ?? "";

  String get getUserEmail => _firebaseUser.value?.email ?? "";

  String get getDisplayName => _firebaseUser.value?.displayName ?? "";

  String get getPhoneNo => _firebaseUser.value?.phoneNumber ?? "";

  /// Called from main.dart on app launch
  @override
  void onReady() {
    _firebaseUser = Rx<User?>(_auth.currentUser);
    _firebaseUser.bindStream(_auth.userChanges());
    FlutterNativeSplash.remove();
    screenRedirect(_firebaseUser.value);
  }

  /// Function to Show Relevant Screen
  screenRedirect(
    User? user, {
    String phoneNumber = '',
    bool pinScreen = false,
    bool stopLoadingWhenReady = false,
  }) async {
    if (user != null) {
      final uid = user.uid;
      final email = user.email;

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .get();

        DateTime? createdAt;
        final data = userDoc.data();
        if (data != null && data.containsKey('createdAt')) {
          createdAt = data['createdAt']?.toDate();
        }

        final now = DateTime.now();
        final isExpired =
            createdAt != null && now.difference(createdAt).inDays >= 7;

        if (isExpired && email != null) {
          // Password expired — sign out and send reset email
          await FirebaseAuth.instance.signOut();
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

          Get.defaultDialog(
            title: "Password Expired",
            middleText:
                "Your password has expired. A reset link has been sent to your email.",
            confirm: ElevatedButton(
              onPressed: () {
                Get.back();
                Get.offAll(() => const LoginScreen());
              },
              child: const Text("OK"),
            ),
          );
          return;
        }

        // Update createdAt to now (extend password validity)
        await FirebaseFirestore.instance.collection('Users').doc(uid).set({
          'createdAt': now,
        }, SetOptions(merge: true));

        // Email verified? Then go to home
        if (user.emailVerified || user.phoneNumber != null) {
          await TLocalStorage.init(uid);
          final userController = Get.find<UserController>();
          await userController.loadCurrentUser();

          final role = data?['role'] ?? '';
          if (role == AppRole.patient.name) {
            Get.offAll(() => HomePage());
          } else if (role == AppRole.caregiver.name) {
            Get.offAll(() => CaregiverDashboardScreen());
          } else {
            Get.offAll(() => HomePage());
          }
        } else {
          Get.offAll(() => VerifyEmailScreen(email: email ?? ""));
        }
      } catch (e) {
        // Fallback on error
        Get.snackbar(
          "Error",
          "Something went wrong while checking user session.",
        );
        Get.offAll(() => const LoginScreen());
      }
    } else {
      // New or logged-out user
      deviceStorage.writeIfNull('isFirstTime', true);
      deviceStorage.read('isFirstTime') != true
          ? Get.offAll(() => const LoginScreen())
          : Get.offAll(() => const OnBoardingScreen());
    }
  }

  /* ---------------------------- Email & Password sign-in ---------------------------------*/

  /// [EmailAuthentication] - SignIn
  Future<UserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user?.uid;

      // Reset counter on success
      failedAttempts = 0;

      // Update createdAt (extend validity)
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      failedAttempts++;

      // Check if user exists in Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      DateTime? createdAt;
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data.containsKey('createdAt')) {
          createdAt = data['createdAt']?.toDate();
        }
      }

      final isExpired =
          createdAt != null && DateTime.now().difference(createdAt).inDays >= 7;

      if (failedAttempts >= 3 || isExpired) {
        failedAttempts = 0; // Reset after handling

        // Try sending password reset email
        try {
          await _auth.sendPasswordResetEmail(email: email);
        } catch (_) {}

        // Throw custom message to be shown by UI
        throw "Too many failed attempts or password expired. A reset link has been sent to your email.";
      }

      // Standard Firebase errors
      if (e.code == 'user-not-found') {
        throw "User not found";
      } else if (e.code == 'wrong-password') {
        throw "Wrong password";
      } else {
        throw TFirebaseAuthException(e.code).message;
      }
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  /// [EmailAuthentication] - REGISTER
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  /// [ReAuthenticate] - ReAuthenticate User
  Future<void> reAuthenticateWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Create a credential
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // ReAuthenticate
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  /// [EmailAuthentication] - FORGET PASSWORD
  Future<void> sendPasswordResetEmail(email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  /// [LogoutUser] - Valid for any authentication.
  Future<void> logout() async {
    try {
      if (Get.isRegistered<UserController>()) {
        UserController.instance.logout();
      }
      _disposeUserScopedControllers();
      await FirebaseAuth.instance.signOut();
      screenRedirect(null);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  void _disposeUserScopedControllers() {
    if (Get.isRegistered<CaregiverController>()) {
      Get.delete<CaregiverController>(force: true);
    }
    if (Get.isRegistered<PatientMedicationsController>()) {
      Get.delete<PatientMedicationsController>(force: true);
    }
    if (Get.isRegistered<NotificationController>()) {
      Get.delete<NotificationController>(force: true);
    }
    if (Get.isRegistered<TestReportListController>()) {
      Get.delete<TestReportListController>(force: true);
    }
    if (Get.isRegistered<TestReportFormController>()) {
      Get.delete<TestReportFormController>(force: true);
    }
    if (Get.isRegistered<TestReportDetailController>()) {
      Get.delete<TestReportDetailController>(force: true);
    }
    if (Get.isRegistered<TestReportAnalyticsController>()) {
      Get.delete<TestReportAnalyticsController>(force: true);
    }
  }

  /// DELETE USER - Remove user Auth and Firestore Account.
  Future<void> deleteAccount() async {
    try {
      await UserRepository.instance.removeUserRecord(_auth.currentUser!.uid);
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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
