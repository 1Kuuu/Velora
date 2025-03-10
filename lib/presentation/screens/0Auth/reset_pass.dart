import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/utils/validators.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ResetPasswordPageState createState() => ResetPasswordPageState();
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void submitForm() {
    if (_formKey.currentState!.validate()) {
      DelightToastBar(
        builder: (context) {
          return const ToastCard(
            title: Text("Success"),
            subtitle: Text("Password reset successful!"),
            leading: Icon(Icons.check_circle, color: Colors.green),
          );
        },
        position: DelightSnackbarPosition.top,
        autoDismiss: true,
        snackbarDuration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 300),
      ).show(context);

      Navigator.pop(context);
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
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),
                const AppLogo(),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Enter Your New Password',
                    style: AppFonts.bold.copyWith(
                      fontSize: 20,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // New Password Field
                CustomInputField(
                  label: 'NEW PASSWORD',
                  controller: passwordController,
                  hintText: 'Enter your new password',
                  obscureText: true,
                  validator: FormValidators.validatePassword,
                ),
                const SizedBox(height: 16),
                // Confirm Password Field
                CustomInputField(
                  label: 'CONFIRM PASSWORD',
                  controller: confirmPasswordController,
                  hintText: 'Re-enter your new password',
                  obscureText: true,
                  validator: (value) => FormValidators.validatePasswordMatch(
                    value,
                    passwordController.text,
                  ),
                ),
                const SizedBox(height: 32),
                // Submit Button
                CustomButton(
                  text: 'SUBMIT',
                  onPressed: submitForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
