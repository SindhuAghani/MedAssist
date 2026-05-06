import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../../../utils/popups/loaders.dart';
import '../models/user_model.dart';
import '../screens/profile/re_authenticate_user_login_form.dart';

import 'package:mindheal/utils/local_storage/storage_utility.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final UserRepository _userRepository = Get.put(UserRepository());

  // Current user
  final Rx<UserModel> user = UserModel.empty().obs;

  final imageUploading = false.obs;
  final profileLoading = false.obs;
  final profileImageUrl = ''.obs;
  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();
  final verifyEmail = TextEditingController();
  final verifyPassword = TextEditingController();
  final hidePassword = false.obs;

  // All patients (for caregiver/doctor dropdowns)
  final RxList<UserModel> _allPatients = <UserModel>[].obs;
  List<UserModel> get allPatients => _allPatients;

  // All doctors
  final RxList<UserModel> _allDoctors = <UserModel>[].obs;
  List<UserModel> get allDoctors => _allDoctors;

  // All caregivers
  final RxList<UserModel> _allCaregivers = <UserModel>[].obs;
  List<UserModel> get allCaregivers => _allCaregivers;

  // Loading states
  final RxBool _isLoadingPatients = false.obs;
  final RxBool _isLoadingDoctors = false.obs;
  final RxBool _isLoadingCaregivers = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  bool get isLoadingPatients => _isLoadingPatients.value;
  bool get isLoadingDoctors => _isLoadingDoctors.value;
  bool get isLoadingCaregivers => _isLoadingCaregivers.value;
  String get errorMessage => _errorMessage.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Load current user from local storage
    await loadCurrentUser();
    await loadAllPatients();
  }

  /// Save user Record from any Registration provider
  Future<void> saveUserRecord({
    UserModel? user,
    UserCredential? userCredentials,
  }) async {
    try {
      // First UPDATE Rx User and then check if user data is already stored. If not store new data
      final userFromDatabase = await _userRepository.fetchUserDetails();
      this.user.value = userFromDatabase;

      // If no record already stored.
      if (this.user.value.id.isEmpty) {
        if (userCredentials != null) {
          // Convert Name to First and Last Name
          final nameParts = UserModel.nameParts(
            userCredentials.user!.displayName ?? '',
          );
          final customUsername = UserModel.generateUsername(
            userCredentials.user!.displayName ?? '',
          );

          // Map data
          final newUser = UserModel(
            id: userCredentials.user!.uid,
            firstName: nameParts[0],
            lastName: nameParts.length > 1
                ? nameParts.sublist(1).join(' ')
                : "",
            userName: customUsername,
            email: userCredentials.user!.email ?? '',
            profilePicture: userCredentials.user!.photoURL ?? '',
            deviceToken: user!.deviceToken,
            isEmailVerified: true,
            isProfileActive: true,
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
            role: AppRole.patient,
            verificationStatus: VerificationStatus.approved,
            phoneNumber: '',
          );

          // Save user data
          await _userRepository.saveUserRecord(newUser);

          // Assign new user to the RxUser so that we can use it through out the app.
          this.user(newUser);
        } else if (user != null) {
          // Save Model when user registers using Email and Password
          await _userRepository.saveUserRecord(user);

          // Assign new user to the RxUser so that we can use it through out the app.
          this.user(user);
        }
      }
    } catch (e) {
      print(e.toString());
      TLoaders.warningSnackBar(
        title: 'Data not saved',
        message:
            'Something went wrong while saving your information. You can re-save your data in your Profile.',
      );
    }
  }

  /// Load current user from local storage
  Future<void> loadCurrentUser() async {
    try {
      //final userId = await TLocalStorage.instance().readData('userId');
      final userId = AuthenticationRepository.instance.getUserID;
      if (userId.isNotEmpty) {
        final userData = await _userRepository.getUserById(userId);
        user.value = userData;
        user.refresh();
      } else {
        user.value = UserModel.empty();
      }
    } catch (e) {
      _errorMessage.value = 'Failed to load user: $e';
    }
  }

  /// Upload Profile Picture
  uploadUserProfilePicture() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxHeight: 512,
        maxWidth: 512,
      );
      if (image != null) {
        imageUploading.value = true;
        final uploadedImage = await _userRepository.uploadImage(
          'Users/Images/Profile/',
          image,
        );
        profileImageUrl.value = uploadedImage;
        Map<String, dynamic> newImage = {'ProfilePicture': uploadedImage};
        await _userRepository.updateSingleField(newImage);
        user.value.profilePicture = uploadedImage;
        user.refresh();

        imageUploading.value = false;
        TLoaders.successSnackBar(
          title: 'Congratulations',
          message: 'Your Profile Image has been updated!',
        );
      }
    } catch (e) {
      imageUploading.value = false;
      TLoaders.errorSnackBar(
        title: 'OhSnap',
        message: 'Something went wrong: $e',
      );
    }
  }

  /// Delete Account Warning
  void deleteAccountWarningPopup() {
    Get.defaultDialog(
      contentPadding: const EdgeInsets.all(TSizes.md),
      title: 'Delete Account',
      middleText:
          'Are you sure you want to delete your account permanently? This action is not reversible and all of your data will be removed permanently.',
      confirm: ElevatedButton(
        onPressed: () async => deleteUserAccount(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.lg),
          child: Text('Delete'),
        ),
      ),
      cancel: OutlinedButton(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
      ),
    );
  }

  /// Delete User Account
  void deleteUserAccount() async {
    try {
      TFullScreenLoader.openLoadingDialog('Processing', TImages.docerAnimation);

      /// First re-authenticate user
      final auth = AuthenticationRepository.instance;
      final provider = auth.firebaseUser!.providerData
          .map((e) => e.providerId)
          .first;
      if (provider.isNotEmpty) {
        // Re Verify Auth Email
        if (provider == 'password') {
          TFullScreenLoader.stopLoading();
          Get.to(() => const ReAuthLoginForm());
        }
      }
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  //   /// -- RE-AUTHENTICATE before deleting
  Future<void> reAuthenticateEmailAndPasswordUser() async {
    try {
      TFullScreenLoader.openLoadingDialog('Processing', TImages.docerAnimation);

      //Check Internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!reAuthFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await AuthenticationRepository.instance
          .reAuthenticateWithEmailAndPassword(
            verifyEmail.text.trim(),
            verifyPassword.text.trim(),
          );
      await AuthenticationRepository.instance.deleteAccount();
      TFullScreenLoader.stopLoading();
      Get.offAllNamed(TRoutes.logIn);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Update user record after login (e.g., to update token)
  Future<void> updateUserRecordWithToken(String newToken) async {
    try {
      // Create a map to store the fields we want to update (e.g., token)
      Map<String, dynamic> updatedFields = {'deviceToken': newToken};

      // Call the repository to update the specific fields
      await _userRepository.updateSingleField(updatedFields);

      // Update the local RxUser object with the new token
      user.value.deviceToken = newToken;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update user record: $e',
      );
    }
  }

  /// Get all patients (for dropdowns)
  Future<void> loadAllPatients() async {
    try {
      _isLoadingPatients.value = true;
      _errorMessage.value = '';

      _allPatients.value = await _userRepository.getAllPatients();
    } catch (e) {
      _errorMessage.value = 'Failed to load patients: $e';
      Get.snackbar(
        'Error',
        'Failed to load patients: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoadingPatients.value = false;
    }
  }

  /// Get all doctors
  Future<void> loadAllDoctors() async {
    try {
      _isLoadingDoctors.value = true;
      _errorMessage.value = '';

      _allDoctors.value = await _userRepository.getAllDoctors();
    } catch (e) {
      _errorMessage.value = 'Failed to load doctors: $e';
    } finally {
      _isLoadingDoctors.value = false;
    }
  }

  /// Get all caregivers
  Future<void> loadAllCaregivers() async {
    try {
      _isLoadingCaregivers.value = true;
      _errorMessage.value = '';

      _allCaregivers.value = await _userRepository.getAllCaregivers();
    } catch (e) {
      _errorMessage.value = 'Failed to load caregivers: $e';
    } finally {
      _isLoadingCaregivers.value = false;
    }
  }

  /// Get user data by ID
  Future<UserModel> getUserData(String userId) async {
    try {
      return await _userRepository.getUserById(userId);
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _userRepository.searchUsers(query);
    } catch (e) {
      throw 'Failed to search users: $e';
    }
  }

  /// Get users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      return await _userRepository.getUsersByIds(userIds);
    } catch (e) {
      throw 'Failed to get users by IDs: $e';
    }
  }

  /// Get active patients only
  Future<List<UserModel>> getActivePatients() async {
    try {
      return await _userRepository.getActivePatients();
    } catch (e) {
      throw 'Failed to get active patients: $e';
    }
  }

  /// Update current user's data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      await _userRepository.updateUser(user.value.id, data);

      // Update local user object
      final updatedUser = await _userRepository.getUserById(user.value.id);
      user.value = updatedUser;

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Get patient count for statistics
  Future<int> getPatientCount() async {
    try {
      return await _userRepository.getPatientCount();
    } catch (e) {
      throw 'Failed to get patient count: $e';
    }
  }

  /// Stream patients for real-time updates
  Stream<List<UserModel>> streamAllPatients() {
    return _userRepository.streamAllPatients();
  }

  /// Get patients with pagination
  Future<List<UserModel>> getPatientsWithPagination({
    required int limit,
    required String? lastDocumentId,
  }) async {
    try {
      return await _userRepository.getPatientsWithPagination(
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
    } catch (e) {
      throw 'Failed to load patients: $e';
    }
  }

  /// Filter patients based on criteria
  List<UserModel> filterPatients({
    String? searchQuery,
    VerificationStatus? verificationStatus,
    bool? isProfileActive,
  }) {
    var filteredPatients = _allPatients;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredPatients = filteredPatients
          .where(
            (patient) =>
                patient.fullName.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                patient.email.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                patient.phoneNumber.contains(searchQuery),
          )
          .toList()
          .obs;
    }

    if (verificationStatus != null) {
      filteredPatients = filteredPatients
          .where((patient) => patient.verificationStatus == verificationStatus)
          .toList()
          .obs;
    }

    if (isProfileActive != null) {
      filteredPatients = filteredPatients
          .where((patient) => patient.isProfileActive == isProfileActive)
          .toList()
          .obs;
    }

    return filteredPatients;
  }

  /// Get patient statistics
  Map<String, int> getPatientStatistics() {
    final total = _allPatients.length;
    final active = _allPatients.where((p) => p.isProfileActive).length;
    final verified = _allPatients
        .where((p) => p.verificationStatus == VerificationStatus.approved)
        .length;
    final pending = _allPatients
        .where((p) => p.verificationStatus == VerificationStatus.pending)
        .length;

    return {
      'total': total,
      'active': active,
      'verified': verified,
      'pending': pending,
    };
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadAllPatients(),
      loadAllDoctors(),
      loadAllCaregivers(),
    ]);
  }

  /// Check if user is a patient
  bool isPatient() {
    return user.value.role == AppRole.patient;
  }

  /// Check if user is a doctor
  bool isDoctor() {
    return user.value.role == AppRole.doctor;
  }

  /// Check if user is a caregiver
  bool isCaregiver() {
    return user.value.role == AppRole.caregiver;
  }

  /// Check if user is an admin
  bool isAdmin() {
    return user.value.role == AppRole.admin;
  }

  /// Logout user
  void logout() {
    user.value = UserModel.empty();
    _allPatients.clear();
    _allDoctors.clear();
    _allCaregivers.clear();
    TLocalStorage.instance().removeData('userId');
  }
}
