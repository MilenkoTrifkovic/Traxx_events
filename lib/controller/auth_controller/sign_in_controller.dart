import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/services/auth_services.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class SignInController extends GetxController {
  final AuthServices _authServices = AuthServices();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  final isLoading = false.obs;
  final isSignUpMode = false.obs;

  // HubSpot-like UX: show OAuth buttons, and optionally expand password form
  final usePassword = false.obs;

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Message observables
  final successMessage = RxnString();
  final errorMessage = RxnString();

  // Auth result
  final authResult = Rxn<UserCredential>();

  // 🔥 Navigation flags
  final shouldNavigateToEmailVerification = false.obs;
  final shouldNavigateToOrganisationInfo = false.obs;
  final shouldNavigateToHostEvents = false.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // UI toggles
  // ─────────────────────────────────────────────

  void toggleSignUpMode() => isSignUpMode.value = !isSignUpMode.value;

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;

  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  void togglePasswordMethod() => usePassword.value = !usePassword.value;

  // ─────────────────────────────────────────────
  // Email + Password auth
  // ─────────────────────────────────────────────

  Future<void> handleEmailPasswordAuth({
    required String email,
    required String password,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      _resetNavigationFlags();
      clearErrorMessage();
      clearSuccessMessage();

      UserCredential userCredential;

      if (isSignUpMode.value) {
        // ───────────── SIGN UP ─────────────
        print('Controller: Creating admin user (signup)');
        userCredential = await _authServices.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 1️⃣ send verification email
        await _authServices.sendEmailVerification();

        // 2️⃣ load profile (role=admin, organisationId=null) - your existing flow
        await _authController.loadUserProfile();

        authResult.value = userCredential;

        // 3️⃣ tell UI to go to email verification page
        shouldNavigateToEmailVerification.value = true;
        return;
      } else {
        // ───────────── SIGN IN ─────────────
        print('Controller: Signing in user');
        userCredential = await _authServices.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        authResult.value = userCredential;
        await _postAuthRoute(userCredential);
      }
    } catch (e) {
      print('Controller: Error occurred: $e');
      _showErrorMessage(_niceError(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // OAuth Providers: Google / Microsoft / Apple
  // Works for BOTH sign-up and sign-in (new users get created automatically)
  // ─────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});

    await _signInWithProvider(provider, label: 'Google');
  }

  Future<void> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com')
      ..setCustomParameters({'prompt': 'select_account'});

    await _signInWithProvider(provider, label: 'Microsoft');
  }

  Future<void> signInWithApple() async {
    final provider = OAuthProvider('apple.com');
    provider.addScope('email');
    provider.addScope('name');

    await _signInWithProvider(provider, label: 'Apple');
  }

  Future<void> _ensureUserProfileExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (snap.exists) return;

    // ✅ Create a default profile for NEW OAuth users
    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': 'admin', // ✅ same as your email/password signup flow
      'organisationId': null, // ✅ new user has no org yet
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _signInWithProvider(
    AuthProvider provider, {
    required String label,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      _resetNavigationFlags();
      clearErrorMessage();
      clearSuccessMessage();

      print('Controller: Signing in with $label');

      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await auth.signInWithPopup(provider);
      } else {
        userCredential = await auth.signInWithProvider(provider);
      }

      authResult.value = userCredential;

      final user = userCredential.user;
      if (user == null) {
        _showErrorMessage('Sign-in failed. Please try again.');
        return;
      }

      // ✅ NEW: ensure profile exists for NEW OAuth users
      await _ensureUserProfileExists(user);

      // Now load profile normally
      await _authController.loadUserProfile();

      await _postAuthRoute(userCredential);
    } on FirebaseAuthException catch (e) {
      print('Controller: FirebaseAuthException: ${e.code} ${e.message}');
      _showErrorMessage(_niceFirebaseAuthError(e));
    } catch (e) {
      print('Controller: OAuth error: $e');
      _showErrorMessage(_niceError(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────
  // Forgot password
  // ─────────────────────────────────────────────

  Future<void> handleForgotPassword(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      _showErrorMessage('Please enter your email address first');
      return;
    }

    try {
      await _authServices.sendPasswordResetEmail(trimmed);
      _showSuccessMessage('Password reset email sent! Check your inbox.');
    } catch (e) {
      _showErrorMessage(_niceError(e));
    }
  }

  // ─────────────────────────────────────────────
  // Post-auth routing (shared)
  // ─────────────────────────────────────────────

  Future<void> _postAuthRoute(UserCredential userCredential) async {
    await _authController.loadUserProfile();

    final user = userCredential.user;
    if (user == null) return;

    final signedInWithPassword =
        user.providerData.any((p) => p.providerId == 'password');

    final isVerified = user.emailVerified;

    // ✅ Only require verification for password users
    if (signedInWithPassword && !isVerified) {
      shouldNavigateToEmailVerification.value = true;
      return;
    }

    if (!_authController.companyInfoExists) {
      shouldNavigateToOrganisationInfo.value = true;
      return;
    }

    shouldNavigateToHostEvents.value = true;
  }

  // ─────────────────────────────────────────────
  // Navigation flags helpers
  // ─────────────────────────────────────────────

  void _resetNavigationFlags() {
    shouldNavigateToHostEvents.value = false;
    shouldNavigateToEmailVerification.value = false;
    shouldNavigateToOrganisationInfo.value = false;
  }

  void clearNavigationFlags() {
    _resetNavigationFlags();
    authResult.value = null;
  }

  // ─────────────────────────────────────────────
  // Message helpers
  // ─────────────────────────────────────────────

  void _showSuccessMessage(String message) => successMessage.value = message;

  void _showErrorMessage(String message) => errorMessage.value = message;

  void clearSuccessMessage() => successMessage.value = null;

  void clearErrorMessage() => errorMessage.value = null;

  // ─────────────────────────────────────────────
  // Error formatting
  // ─────────────────────────────────────────────

  String _niceError(Object e) {
    final s = e.toString();

    // If it’s a FirebaseAuthException wrapped or printed, keep it clean
    if (s.contains('firebase_auth')) {
      return 'Authentication failed. Please try again.';
    }
    return s.replaceFirst('Exception: ', '').trim();
  }

  String _niceFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'This email already exists with a different sign-in method. Please try the other provider.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed before completing.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled yet. Please enable it in Firebase.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error. Please try again.';
    }
  }
}
