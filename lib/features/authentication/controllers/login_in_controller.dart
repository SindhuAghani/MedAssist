import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/services/notifications/notification_service.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../../personalization/controllers/user_controller.dart';



class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final hidePassword = true.obs;
  final rememberMe = false.obs;
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  /// New 👇
  int failedAttempts = 0;
  final int maxAttempts = 3;

  @override
  void onInit() {
    email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
    password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    super.onInit();
  }

  /// -- Email and Password SignIn
  Future<void> emailAndPasswordSignIn() async {
    try {
      TFullScreenLoader.openLoadingDialog('Logging you in...', TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.customToast(message: 'No Internet Connection');
        return;
      }

      if (!loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      }

      final userCredentials = await AuthenticationRepository.instance
          .loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      failedAttempts = 0; // Reset on success ✅

      final token = await TNotificationService.getToken();
      final userController = Get.put(UserController());
      await userController.updateUserRecordWithToken(token);

      TFullScreenLoader.stopLoading();
      await AuthenticationRepository.instance.screenRedirect(userCredentials.user);

    } catch (e) {
      failedAttempts++; // Track failed login attempts

      TFullScreenLoader.stopLoading();

      if (failedAttempts >= maxAttempts) {
        failedAttempts = 0;
        await AuthenticationRepository.instance.sendPasswordResetEmail(email.text.trim());
        TLoaders.warningSnackBar(
          title: "Too Many Attempts",
          message: "Reset link sent to your email. Try again after resetting your password.",
        );
      } else {
        TLoaders.errorSnackBar(
          title: 'Login Failed',
          message: e.toString(),
        );
      }
    }
  }
}

