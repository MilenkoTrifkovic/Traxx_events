import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Controller for managing email verification functionality
class EmailVerificationController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables
  var isVerified = false.obs;
  var isLoading = false.obs;
  var isResendDisabled = false.obs;
  var resendCountdown = 0.obs;
  var userEmail = ''.obs;
  var isCheckingVerification = false.obs;

  // Message observables for reactive UI
  var successMessage = RxnString();
  var errorMessage = RxnString();

  // Navigation flags for reactive UI
  var shouldNavigateToHostEvents = false.obs;
  var shouldNavigateToLogin = false.obs;

  // Timers
  Timer? _verificationTimer;
  Timer? _resendTimer;
  Timer? _countdownTimer;

  // Constants
  static const int resendCooldownSeconds = 15;
  static const int verificationCheckInterval = 3; // seconds

  @override
  void onInit() {
    super.onInit();
    _initializeUserEmail();
    _startVerificationPolling();
    print('EmailVerificationController initialized for $userEmail');
  }

  @override
  void onClose() {
    _stopAllTimers();
    super.onClose();
  }

  void _startVerificationPolling() {
    _verificationTimer = Timer.periodic(
      Duration(seconds: verificationCheckInterval),
      (_) async {
        await _auth.currentUser?.reload();
        print("Checking email verification status...");
        if (_auth.currentUser?.emailVerified ?? false) {
          _verificationTimer?.cancel();
          _showSuccessMessage("Email verified!");
          isVerified.value = true;
          shouldNavigateToHostEvents.value = true;
        }
      },
    );
  }

  /// Initialize user email from current user
  void _initializeUserEmail() {
    final user = _auth.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? '';
    }
  }

  /// Stop all running timers
  void _stopAllTimers() {
    _verificationTimer?.cancel();
    _resendTimer?.cancel();
    _countdownTimer?.cancel();
  }

  /// Check email verification status and set navigation flags
  Future<void> checkEmailVerificationStatus() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        _showErrorMessage('No user found. Please log in again.');
        return;
      }

      // Check verification status one more time before proceeding
      await user.reload();
      final updatedUser = _auth.currentUser;

      if (updatedUser?.emailVerified == true) {
        _stopAllTimers();
        _showSuccessMessage('Email successfully verified!');
        shouldNavigateToHostEvents.value = true;
      } else {
        _showErrorMessage(
            'Email is not verified yet. Please verify your email first.');
      }
    } catch (e) {
      _showErrorMessage(
          'Error checking verification status. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    if (isResendDisabled.value) return;

    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        _showErrorMessage('No user found. Please log in again.');
        return;
      }

      await user.sendEmailVerification();

      _showSuccessMessage('Verification email sent! Please check your inbox.');
      _startResendCooldown();
    } on FirebaseAuthException catch (e) {
      _showErrorMessage(_handleAuthException(e));
    } catch (e) {
      _showErrorMessage('Failed to send verification email. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Start cooldown period after resending email
  void _startResendCooldown() {
    isResendDisabled.value = true;
    resendCountdown.value = resendCooldownSeconds;

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (resendCountdown.value > 0) {
        resendCountdown.value--;
      } else {
        isResendDisabled.value = false;
        timer.cancel();
      }
    });
  }

  /// Sign out and set navigation flag
  Future<void> signOutAndReturnToLogin() async {
    try {
      isLoading.value = true;
      _stopAllTimers();

      await _auth.signOut();
      shouldNavigateToLogin.value = true;
    } catch (e) {
      _showErrorMessage('Error signing out. Please try again.');
    } finally {
      isLoading.value = false;
    }
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

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Too many requests. Please wait before trying again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'User not found. Please log in again.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }

  /// Clear navigation flags after navigation is handled
  void clearNavigationFlags() {
    shouldNavigateToHostEvents.value = false;
    shouldNavigateToLogin.value = false;
  }
}
