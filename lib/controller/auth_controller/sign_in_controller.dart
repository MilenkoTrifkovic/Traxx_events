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

  // HubSpot-like UX: show OAuth buttons + optionally expand password form
  final usePassword = false.obs;

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Message observables
  final successMessage = RxnString();
  final errorMessage = RxnString();

  // Auth result
  final authResult = Rxn<UserCredential>();

  // Navigation flags
  final shouldNavigateToEmailVerification = false.obs;
  final shouldNavigateToOrganisationInfo = false.obs;
  final shouldNavigateToHostEvents = false.obs;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------------------------------------------------
  // ✅ NEW: track active method + allow cancel / switching methods
  // ------------------------------------------------------------------
  final activeAuthMethod =
      RxnString(); // 'google'|'microsoft'|'apple'|'password'
  final _opVersion = 0.obs;

  String get activeAuthMethodLabel {
    switch (activeAuthMethod.value) {
      case 'google':
        return 'Google';
      case 'microsoft':
        return 'Microsoft';
      case 'apple':
        return 'Apple';
      case 'password':
        return 'Password';
      default:
        return '…';
    }
  }

  int _beginAuth(String method) {
    activeAuthMethod.value = method;
    _opVersion.value = _opVersion.value + 1;
    isLoading.value = true;
    return _opVersion.value;
  }

  bool _isStale(int op) => op != _opVersion.value;

  /// Cancels the *current* auth attempt from a UI perspective.
  /// If the provider completes later, we ignore it and sign out.
  Future<void> cancelCurrentAuth({bool silent = false}) async {
    _opVersion.value = _opVersion.value + 1; // invalidate pending ops
    activeAuthMethod.value = null;
    isLoading.value = false;

    if (!silent) {
      successMessage.value = 'Cancelled. Choose another sign-in method.';
    }
  }

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

    final op = _beginAuth('password');

    try {
      _resetNavigationFlags();
      clearErrorMessage();
      clearSuccessMessage();

      UserCredential userCredential;

      if (isSignUpMode.value) {
        // SIGN UP
        userCredential = await _authServices.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // If user cancelled while waiting, ignore and sign out
        if (_isStale(op)) {
          await _safeSignOutIfSameUser(userCredential.user);
          return;
        }

        await _authServices.sendEmailVerification();

        // ensure profile exists (rare but safe)
        final u = userCredential.user;
        if (u != null) {
          await _ensureUserProfileExists(u);
        }

        // await _authController.loadUserProfile();
        authResult.value = userCredential;

        shouldNavigateToEmailVerification.value = true;
        return;
      } else {
        // SIGN IN
        userCredential = await _authServices.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (_isStale(op)) {
          await _safeSignOutIfSameUser(userCredential.user);
          return;
        }

        authResult.value = userCredential;
        await _postAuthRoute(userCredential);
      }
    } catch (e) {
      if (!_isStale(op)) {
        _showErrorMessage(_niceError(e));
      }
    } finally {
      if (!_isStale(op)) {
        isLoading.value = false;
        activeAuthMethod.value = null;
      }
    }
  }

  // ─────────────────────────────────────────────
  // OAuth Providers: Google / Microsoft / Apple
  // Works for BOTH sign-up and sign-in (new users get created automatically)
  // ─────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    await _signInWithProvider(provider, method: 'google', label: 'Google');
  }

  Future<void> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com')
      ..setCustomParameters({'prompt': 'select_account'});
    await _signInWithProvider(provider,
        method: 'microsoft', label: 'Microsoft');
  }

  Future<void> signInWithApple() async {
    final provider = OAuthProvider('apple.com')
      ..addScope('email')
      ..addScope('name');
    await _signInWithProvider(provider, method: 'apple', label: 'Apple');
  }

  Future<void> _ensureUserProfileExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': 'admin', // ✅ same as your email/password signup flow
      'organisationId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'modifiedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _signInWithProvider(
    AuthProvider provider, {
    required String method, // 'google'|'microsoft'|'apple'
    required String label,
  }) async {
    if (isLoading.value) return;

    final op = _beginAuth(method);

    try {
      _resetNavigationFlags();
      clearErrorMessage();
      clearSuccessMessage();

      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await auth.signInWithPopup(provider);
      } else {
        userCredential = await auth.signInWithProvider(provider);
      }

      // If user cancelled while popup was open, ignore and sign out
      if (_isStale(op)) {
        await _safeSignOutIfSameUser(userCredential.user);
        return;
      }

      authResult.value = userCredential;

      final user = userCredential.user;
      if (user == null) {
        _showErrorMessage('Sign-in failed. Please try again.');
        return;
      }

      // ensure profile exists for NEW OAuth users
      await _ensureUserProfileExists(user);

      // load profile & route
      // await _authController.loadUserProfile();
      await _postAuthRoute(userCredential);
    } on FirebaseAuthException catch (e) {
      if (!_isStale(op)) {
        _showErrorMessage(_niceFirebaseAuthError(e));
      }
    } catch (e) {
      if (!_isStale(op)) {
        _showErrorMessage(_niceError(e));
      }
    } finally {
      if (!_isStale(op)) {
        isLoading.value = false;
        activeAuthMethod.value = null;
      }
    }
  }

  Future<void> _safeSignOutIfSameUser(User? u) async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (u != null && current != null && current.uid == u.uid) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // ignore
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
    // await _authController.loadUserProfile();

    final user = userCredential.user;
    if (user == null) return;

    final signedInWithPassword =
        user.providerData.any((p) => p.providerId == 'password');

    // Only require verification for password users
    if (signedInWithPassword && !user.emailVerified) {
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
    if (s.contains('firebase_auth')) {
      return 'Authentication failed. Please try again.';
    }
    return s.replaceFirst('Exception: ', '').trim();
  }

  String _niceFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'This email already exists with a different sign-in method. Please try the original provider.';
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
