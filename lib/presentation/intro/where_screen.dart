import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/presentation/intro/welcome_screen.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhereScreen extends StatefulWidget {
  const WhereScreen({super.key});

  @override
  State<WhereScreen> createState() => _WhereScreenState();
}

class _WhereScreenState extends State<WhereScreen> {
  final Map<String, bool> locationPreferences = {
    'Coastal Routes': false,
    'City Streets': false,
    'Parks': false,
    'Mountains': false,
    'Country Routes': false,
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveAndNavigate() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showToast("Error", "User not found!", Icons.error, Colors.red);
        return;
      }

      // 🔹 Get only selected preferences (true values)
      final selectedLocations = locationPreferences.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // 🔹 Store preferences in Firestore
      await _firestore.collection('user_preferences').doc(userId).set({
        'location_preferences': selectedLocations,
      }, SetOptions(merge: true));

      // 🔹 Save onboarding completion in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);

      // 🎉 Show success toast
      _showToast("Saved!", "Your location preferences have been saved.",
          Icons.check_circle, Colors.green);

      // ✅ Navigate to WelcomeScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      // ❌ Show error toast
      _showToast("Error", "Failed to save: $e", Icons.error, Colors.red);
    }
  }

  void _showToast(String title, String message, IconData icon, Color color) {
    if (mounted) {
      DelightToastBar(
        builder: (context) {
          return ToastCard(
            title: Text(title),
            subtitle: Text(message),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 30,
              ),
              const SizedBox(height: 20),
              const Text(
                'WHERE',
                style: TextStyle(
                  fontSize: 36,
                  color: Color(0xFFB22222),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'DO YOU LIKE TO RIDE?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: locationPreferences.keys.map((String key) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            key,
                            style: const TextStyle(fontSize: 22),
                          ),
                          value: locationPreferences[key],
                          onChanged: (bool? value) {
                            setState(() {
                              locationPreferences[key] = value ?? false;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A1818),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
