import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 🔹 Sign up with email & password
  Future<bool> signUpWithEmail({
    required BuildContext context,
    required String username,
    required String email,
    required String password,
    required String confirmPassword, // 👈 Added confirmPassword parameter
  }) async {
    try {
      // 🔹 Validate Password Match
      if (password != confirmPassword) {
        _showToast(context, "Passwords do not match!", Icons.error, Colors.red);
        return false;
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        User user = userCredential.user!;

        // ✅ Update Firebase Auth profile
        await user.updateDisplayName(username);
        await user.reload(); // Refresh user info

        // ✅ Save user info in Firestore (Unified Collection)
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'userName': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'setupComplete':
              false, // 👈 Ensure this is false for onboarding logic
        });

        return true;
      }
      return false;
    } catch (e) {
      _showToast(context, "Signup failed: $e", Icons.error, Colors.red);
      return false;
    }
  }

  /// 🔹 Log in with email & password
  Future<UserCredential?> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _showToast(
          context, "Login Successful!", Icons.check_circle, Colors.green);
      return userCredential;
    } catch (e) {
      _showToast(context, "Login failed: $e", Icons.error, Colors.red);
      return null;
    }
  }

  /// 🔹 Google Sign-In
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut(); // Ensure fresh login

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // 🔹 New Google User → Add Firestore Data
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'userName': user.displayName ?? "Google User",
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'setupComplete': false, // 👈 Ensure onboarding logic works
          });
        }
      }

      return userCredential;
    } catch (e) {
      _showToast(context, "Google Sign-In failed: $e", Icons.error, Colors.red);
      return null;
    }
  }

  /// 🔹 Logout function (Now handles onboarding reset)
  Future<void> signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasCompletedOnboarding'); // ✅ Clear onboarding flag

    await _auth.signOut();
    await _googleSignIn.signOut();

    // ✅ Ensure auth state change is processed
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// 🔹 Show DelightToastBar notifications
  void _showToast(
      BuildContext context, String message, IconData icon, Color color) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: Text(message),
          leading: Icon(icon, color: color),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }
}
