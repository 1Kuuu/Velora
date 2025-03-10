import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/data/sources/auth_service.dart';
import 'package:velora/presentation/screens/0Auth/auth_gate.dart';
import 'package:velora/presentation/screens/0Auth/forgot_password.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
// Import auth_gate.dart

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Create an instance of AuthService
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Email & Password Login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _authService.loginWithEmail(
          context: context, // Pass the context
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (mounted) {
          DelightToastBar(
            builder: (context) {
              return const ToastCard(
                title: Text('Success'),
                subtitle: Text('Login successful!'),
                leading: Icon(Icons.check_circle, color: Colors.green),
              );
            },
            position: DelightSnackbarPosition.top,
            autoDismiss: true,
            snackbarDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 300),
          ).show(context);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AuthGate()), // Navigate to AuthGate
          );
        }
      } catch (e) {
        if (mounted) {
          DelightToastBar(
            builder: (context) {
              return ToastCard(
                title: const Text('Error'),
                subtitle: Text("Login failed: $e"),
                leading: const Icon(Icons.error, color: Colors.red),
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
  }

  /// Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      await _authService
          .signInWithGoogle(context); // Ensure `context` is passed if required

      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return const ToastCard(
              title: Text('Success'),
              subtitle: Text('Google login successful!'),
              leading: Icon(Icons.check_circle, color: Colors.green),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context); // Ensure `context` is passed

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const AuthGate()), // Navigate to AuthGate
        );
      }
    } catch (e) {
      if (mounted) {
        DelightToastBar(
          builder: (context) {
            return ToastCard(
              title: const Text('Error'),
              subtitle: Text("Google Sign-In failed: $e"),
              leading: const Icon(Icons.error, color: Colors.red),
            );
          },
          position: DelightSnackbarPosition.top,
          autoDismiss: true,
          snackbarDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 300),
        ).show(context); // Ensure `context` is passed
      }
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
                CustomTitleText(text: 'LOGIN'),
                const SizedBox(height: 2),

                // Email Input
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

                // Password Input
                CustomInputField(
                  label: 'PASSWORD',
                  controller: passwordController,
                  hintText: 'Enter your password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Login Button
                Center(
                  child: CustomButton(
                    text: 'LOGIN',
                    onPressed: _login,
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.linkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(child: CustomDivider()),
                const SizedBox(height: 24),

                // Google Sign-In Button
                Center(
                  child: CustomButton(
                    text: 'With Google',
                    onPressed: _signInWithGoogle,
                    iconPath: 'assets/images/Google.png',
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up Navigation
                AccountNavigationRow(
                  questionText: "Don't have an account?",
                  actionText: "Sign Up",
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signup');
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
