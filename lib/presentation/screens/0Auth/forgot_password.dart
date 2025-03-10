import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/0Auth/reset_pass.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      DelightToastBar(
        builder: (context) {
          return const ToastCard(
            title: Text("Error"),
            subtitle: Text("Please enter your email"),
            leading: Icon(Icons.error, color: Colors.red),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: const Duration(seconds: 2), // ✅ Must be longer
        animationDuration:
            const Duration(milliseconds: 300), // ✅ Shorter duration
      ).show(context);
      return;
    }

    // Navigate to Reset Password Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              const Center(child: AppLogo()),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'FORGOT PASSWORD?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomInputField(
                label: 'EMAIL',
                controller: emailController,
                hintText: 'Enter your email',
              ),
              const SizedBox(height: 32),
              Center(
                child: CustomButton(
                  text: 'RESET PASSWORD',
                  onPressed: _resetPassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
