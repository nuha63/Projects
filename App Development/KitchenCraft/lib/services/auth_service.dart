import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign-In for Web
  Future<UserCredential?> signInWithGoogleWeb() async {
    try {
      debugPrint('AuthService: Starting Web Google Sign-In');

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      final userCredential = await _auth.signInWithPopup(googleProvider);

      debugPrint('AuthService: Web sign-in successful for ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException - ${e.code}: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Google Sign-In Web Error: $e');
      rethrow;
    }
  }

  // Google Sign-In for Mobile (Android/iOS)
  Future<UserCredential?> signInWithGoogleMobile() async {
    try {
      debugPrint('AuthService: Starting Mobile Google Sign-In');

      // Sign out first to ensure account picker shows
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('AuthService: User cancelled sign-in');
        return null; // User cancelled
      }

      debugPrint('AuthService: Google user signed in: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('AuthService: Missing tokens from Google Auth');
        throw FirebaseAuthException(
          code: 'missing-google-auth-token',
          message: 'Failed to get authentication tokens from Google',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('AuthService: Mobile sign-in successful for ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException - ${e.code}: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Google Sign-In Mobile Error: $e');
      rethrow;
    }
  }

  // Universal Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        debugPrint('AuthService: Platform is Web');
        return await signInWithGoogleWeb();
      } else {
        debugPrint('AuthService: Platform is Mobile');
        return await signInWithGoogleMobile();
      }
    } catch (e) {
      debugPrint('AuthService: Error in signInWithGoogle: $e');
      rethrow;
    }
  }

  // Email & Password Sign In
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Signing in with email: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('AuthService: Email sign-in successful for ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Email sign-in failed - ${e.code}: ${e.message}');
      rethrow;
    }
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Creating account for email: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint('AuthService: Account created for ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Sign-up failed - ${e.code}: ${e.message}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('AuthService: Signing out');

      // Sign out from Google if signed in
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut();

      debugPrint('AuthService: Sign-out successful');
    } catch (e) {
      debugPrint('AuthService: Sign-out error: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('AuthService: Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      debugPrint('AuthService: Password reset email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Password reset failed - ${e.code}: ${e.message}');
      rethrow;
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
      debugPrint('AuthService: Display name updated to: $displayName');
    } catch (e) {
      debugPrint('AuthService: Failed to update display name: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      debugPrint('AuthService: Deleting account');

      await _auth.currentUser?.delete();

      debugPrint('AuthService: Account deleted');
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Account deletion failed - ${e.code}: ${e.message}');
      rethrow;
    }
  }
}