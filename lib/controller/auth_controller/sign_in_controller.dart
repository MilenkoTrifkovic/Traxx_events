import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/services/auth_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';

/// Controller for managing sign-in and sign-up functionality
class SignInController extends GetxController {
  final AuthServices _authServices = AuthServices();
  final CloudFunctionsService _cloudFunctionsService =
      Get.find<CloudFunctionsService>();

  // Observables
  var isLoading = false.obs;
  var isSignUpMode = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  // Message observables for reactive UI
  var successMessage = RxnString();
  var errorMessage = RxnString();

  // Form validation result observable
  var authResult = Rxn<UserCredential>();
  var shouldNavigateToEmailVerification = false.obs;
  var shouldNavigateToOrganisationInfo = false.obs;
  var shouldNavigateToHostEvents = false.obs;

  /// Toggle between sign-in and sign-up modes
  void toggleSignUpMode() {
    isSignUpMode.value = !isSignUpMode.value;
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Handle email/password authentication
  Future<void> handleEmailPasswordAuth({
    required String email,
    required String password,
  }) async {
    if (isLoading.value) return; // Prevent double submission

    try {
      isLoading.value = true;
      _resetNavigationFlags();

      UserCredential userCredential;

      if (isSignUpMode.value) {
        print('Controller: Creating admin user');
        // Call cloud function to create admin user
        userCredential = await _authServices.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Controller: Creating admin user completed');

        // Send email verification for new users
        print('Controller: Sending email verification');
        await _authServices.sendEmailVerification();
        print('Controller: Email verification sent');
      } else {
        print('Controller: Signing in user');
        userCredential = await _authServices.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Controller: User signed in');
      }

      authResult.value = userCredential;

      // Set navigation flags based on email verification status
      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        print('Controller: Should navigate to email verification');
        shouldNavigateToEmailVerification.value = true;
      } else if (await _checkIfOrganisationExists() == false) {
        shouldNavigateToOrganisationInfo.value = true;
      } else {
        print('Controller: Should navigate to host events');
        shouldNavigateToHostEvents.value = true;
      }
    } catch (e) {
      print('Controller: Error occurred: $e');
      _showErrorMessage(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Checks if organisation info already exists for the current user
  /// Returns true if organisation exists, false otherwise
  Future<bool> _checkIfOrganisationExists() async {
    try {
      print('Checking if organisation info already exists...');

      final exists = await _cloudFunctionsService.checkOrganisationInfo();

      print('Organisation exists: $exists');
      return exists;
    } catch (e) {
      print('Error checking organisation existence: $e');
      rethrow;
    }
  }

  /// Handle forgot password
  Future<void> handleForgotPassword(String email) async {
    if (email.trim().isEmpty) {
      _showErrorMessage('Please enter your email address first');
      return;
    }

    try {
      await _authServices.sendPasswordResetEmail(email.trim());
      _showSuccessMessage('Password reset email sent! Check your inbox.');
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  /// Reset navigation flags
  void _resetNavigationFlags() {
    shouldNavigateToEmailVerification.value = false;
    shouldNavigateToHostEvents.value = false;
  }

  /// Clear navigation flags after navigation
  void clearNavigationFlags() {
    _resetNavigationFlags();
    authResult.value = null;
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    successMessage.value = message;
  }

  /// Show error message
  void _showErrorMessage(String message) {
    errorMessage.value = message;
  }

  /// Clear success message
  void clearSuccessMessage() {
    successMessage.value = null;
  }

  /// Clear error message
  void clearErrorMessage() {
    errorMessage.value = null;
  }
}
