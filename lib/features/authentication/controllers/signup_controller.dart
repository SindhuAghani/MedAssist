import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../personalization/models/user_model.dart';
import '../screens/signup/verify_email.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final hidePassword = true.obs;
  final privacyPolicy = true.obs;
  final email = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final phoneNumber = TextEditingController();
  final selectedCountryCode = RxString('+44');
  final selectedRole = AppRole.patient.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  /// -- SIGNUP
  Future<void> signup() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog('We are processing your information...', TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Privacy Policy Check
      if (!privacyPolicy.value) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
            title: 'Accept Privacy Policy',
            message: 'In order to create account, you must have to read and accept the Privacy Policy & Terms of Use.');
        return;
      }

      // Register user in the Firebase Authentication & Save user data in the Firebase
      await AuthenticationRepository.instance.registerWithEmailAndPassword(email.text.trim(), password.text.trim());

      final token = await TNotificationService.getToken();

      // Save Authenticated user data in the Firebase Firestore
      final newUser = UserModel(
        id: AuthenticationRepository.instance.getUserID,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        userName: username.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        profilePicture: '',
        deviceToken: token,
        isEmailVerified: false,
        isProfileActive: false,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        role: selectedRole.value,
        verificationStatus: VerificationStatus.approved,
      );

      final userController = Get.put(UserController());
      await userController.saveUserRecord(user: newUser);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(
          title: 'Congratulations', message: 'Your account has been created! Verify email to continue.');

      // Move to Verify Email Screen
      Get.to(() => const VerifyEmailScreen());
    } catch (e) {
      // Show some Generic Error to the user
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }
}
