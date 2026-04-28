import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resume_analyzer/domain/models/models.dart';

/// Authentication service wrapping Firebase Auth.
///
/// Google Sign-In flow:
///   • Web     → Firebase `signInWithPopup` (no google_sign_in package needed)
///   • Mobile/Desktop → `google_sign_in` 2.x singleton → Firebase credential
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // google_sign_in 2.x uses a singleton — GoogleSignIn.instance.
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  // ─── Auth state ───────────────────────────────────────────────

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

  // ─── Sign in / sign up ────────────────────────────────────────

  /// Sign in with email and password.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
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
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
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

  /// Sign in with Google.
  ///
  /// • Web     → Firebase `signInWithPopup`
  /// • Android/iOS → `google_sign_in` v7 `authenticate()` → Firebase credential
  /// • Windows → not supported (google_sign_in doesn't support Windows)
  Future<AppUser> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ── Web: Firebase popup ───────────────────────────────────
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final cred = await _auth.signInWithPopup(provider);
        final user = cred.user;
        if (user == null) throw AuthException('Google sign-in failed.');
        return _mapUser(user);
      }

      // Guard: google_sign_in only works on Android / iOS.
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        throw AuthException(
          'Google Sign-In is only supported on Android and iOS.\n'
          'Please use Email/Password sign-in on this platform.',
        );
      }

      // ── Android / iOS: google_sign_in v7 ─────────────────────
      // authenticate() shows the account picker (Credential Manager on Android).
      // Throws GoogleSignInException if user cancels — caught by the catch below.
      final result = await _googleSignIn.authenticate();

      // authentication is a Future<GoogleSignInAuthentication> in v7.
      final googleAuth = await result.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw AuthException(
          'Could not obtain Google ID token. '
          'Make sure your SHA-1 fingerprint is registered in the Firebase Console '
          'under Project Settings → Android app.',
        );
      }

      final firebaseCred = GoogleAuthProvider.credential(
        // In google_sign_in v7, authenticate() provides only idToken.
        idToken: idToken,
      );

      final userCred = await _auth.signInWithCredential(firebaseCred);
      final user = userCred.user;
      if (user == null) throw AuthException('Google sign-in failed.');
      return _mapUser(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
        throw AuthException('Google sign-in was cancelled.');
      }
      throw AuthException(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code ?? 'unknown'));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Sign out from Firebase AND Google (account picker shows next time).
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
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

  // ─── Private ─────────────────────────────────────────────────

  AppUser _mapUser(User user) => AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );

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
      case 'invalid-credential':
        return 'Invalid credentials. Please try signing in again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. Try a different sign-in method.';
      default:
        return 'Authentication failed (code: $code). Please try again.';
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
