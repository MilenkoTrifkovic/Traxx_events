import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create account with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Services: Creating admin user');
      // Call cloud function to create admin user
      final result =
          await FirebaseFunctions.instance.httpsCallable('signupAdmin').call({
        'email': email,
        'password': password,
      });

      // Log the result for debugging (optional)
      print('Cloud function result: ${result.data}');

      // Wait a bit for the user creation to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      // The cloud function should create the user, so we now sign them in
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseFunctionsException catch (e) {
      // If cloud function fails, don't try to sign in
      throw _handleFunctionsException(e);
    } on FirebaseAuthException catch (e) {
      // If sign-in fails after cloud function succeeds, it might be because
      // the user was created but with different credentials or timing issues
      print('Auth error after cloud function: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during account creation: $e';
    }
  } // Send email verification

  Future<void> sendEmailVerification() async {
    await currentUser?.sendEmailVerification();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  // Handle Firebase Functions exceptions
  String _handleFunctionsException(FirebaseFunctionsException e) {
    // Prefer backend-provided message when available
    final backendMessage = e.message;

    switch (e.code) {
      case 'permission-denied':
        return backendMessage ??
            'Permission denied. Please check your access rights.';
      case 'not-found':
        return backendMessage ?? 'The requested function was not found.';
      case 'already-exists':
        return backendMessage ?? 'The account already exists for this email.';
      case 'failed-precondition':
        return backendMessage ??
            'Invalid request. Please check your information.';
      case 'invalid-argument':
        // This is the one you are seeing now.
        return backendMessage ?? 'Invalid email or password format.';
      case 'unauthenticated':
        return backendMessage ?? 'Authentication required. Please try again.';
      case 'unavailable':
        return backendMessage ??
            'Service temporarily unavailable. Please try again later.';
      default:
        return backendMessage ??
            'An unexpected error occurred during account creation.';
    }
  }

  Future<void> signUpAdmin() async {
    // Add your sign-up logic here
  }
  // Add your authentication methods here
}
