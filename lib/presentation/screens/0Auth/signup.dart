import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/data/sources/auth_service.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// 🔹 Email & Password Signup with Firestore Storage
  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      final result = await _authService.signUpWithEmail(
        context: context,
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: '',
      );

      print("Signup result: $result"); // Debugging

      if (mounted && result == true) {
        // ✅ Show Success Toast
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text('Signup Successful!'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);

        // ✅ Wait before navigating
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          print("Navigating to login...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        print("Signup failed or returned false");
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text('Signup Failed'),
              leading: Icon(Icons.error, color: Colors.red),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context);
      }
    }
  }

  /// 🔹 Google Sign-Up with Firestore Storage
  Future<void> _signInWithGoogle() async {
    final user = await _authService.signInWithGoogle(context);

    if (mounted && user != null) {
      DelightToastBar(
        builder: (context) {
          return const ToastCard(
            title: Text('Success'),
            leading: Icon(Icons.check_circle, color: Colors.green),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 300),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(),
                CustomTitleText(text: 'SIGN UP'),
                const SizedBox(height: 2),

                // Username Input with Validation
                CustomInputField(
                  label: 'USERNAME',
                  controller: usernameController,
                  hintText: 'Enter your username',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Username is required'
                      : null,
                ),

                const SizedBox(height: 16),

                // Email Input with Validation
                CustomInputField(
                  label: 'EMAIL',
                  controller: emailController,
                  hintText: 'Enter your email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Input with Validation
                CustomInputField(
                  label: 'PASSWORD',
                  controller: passwordController,
                  hintText: 'Enter your password',
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 8)
                      ? 'Password must be at least 8 characters'
                      : null,
                ),

                const SizedBox(height: 16),

                // Confirm Password Input with Validation
                CustomInputField(
                  label: 'CONFIRM PASSWORD',
                  controller: confirmPasswordController,
                  hintText: 'Re-enter your password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Signup Button
                Center(
                  child: CustomButton(
                    text: 'SIGN UP',
                    onPressed: _signup,
                  ),
                ),

                const SizedBox(height: 24),

                Center(child: CustomDivider()),
                const SizedBox(height: 24),

                // Google Sign-Up Button
                Center(
                  child: CustomButton(
                    text: 'With Google',
                    onPressed: _signInWithGoogle,
                    iconPath: 'assets/images/Google.png',
                  ),
                ),

                const SizedBox(height: 24),

                // Login Navigation
                AccountNavigationRow(
                  questionText: "Already have an account?",
                  actionText: "Log In",
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
