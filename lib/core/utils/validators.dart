class FormValidators {
  static var validateEmail;

  // Validates if the password meets complexity requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password cannot be empty";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return "Password must contain at least one uppercase letter";
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return "Password must contain at least one number";
    }
    return null;
  }

  // Validates if the passwords match
  static String? validatePasswordMatch(String? value, String password) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }
    if (value != password) {
      return "Passwords do not match";
    }
    return null;
  }
}
