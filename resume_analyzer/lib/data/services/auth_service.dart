import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:resume_analyzer/domain/models/models.dart';

/// Authentication service wrapping Firebase Auth.
/// Uses Firebase Auth directly for Google Sign-In (works on both web and mobile).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes mapped to domain model.
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return _mapUser(user);
    });
  }

  /// Current user as domain model.
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _mapUser(user);
  }

  /// Sign in with email and password.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AuthException('Sign in failed: no user returned.');
      return _mapUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code ?? 'unknown'));
    }
  }

  /// Register with email and password.
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AuthException('Sign up failed: no user returned.');

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      return AppUser(
        uid: user.uid,
        email: user.email,
        displayName: displayName ?? user.displayName,
        photoUrl: user.photoURL,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code ?? 'unknown'));
    }
  }

  /// Sign in with Google using Firebase Auth directly.
  /// On web: uses signInWithPopup (no google_sign_in package needed).
  /// On mobile: uses signInWithProvider.
  Future<AppUser> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      UserCredential userCredential;

      if (kIsWeb) {
        // Web: popup-based sign-in
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: redirect-based sign-in
        userCredential = await _auth.signInWithProvider(googleProvider);
      }

      final user = userCredential.user;
      if (user == null) throw AuthException('Google sign-in failed.');

      return _mapUser(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
        throw AuthException('Google sign-in was cancelled.');
      }
      throw AuthException(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code ?? 'unknown'));
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code ?? 'unknown'));
    }
  }

  /// Map Firebase User to domain AppUser.
  AppUser _mapUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  /// Map Firebase error codes to user-friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
