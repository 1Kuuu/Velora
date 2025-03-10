import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/presentation/screens/1Home/home.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes back button
        title: const Text('Welcome'),
        titleTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_preferences')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              _showErrorToast(context, 'Failed to load data.');
              return const Center(child: Text('Something went wrong!'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              _showErrorToast(context, 'User preferences not found.');
              return const Center(child: Text('No data available!'));
            }

            final rawData = snapshot.data!.data();

            // Debugging: Print Firestore data
            print("Raw Firestore Data: $rawData");

            if (rawData is! Map<String, dynamic>) {
              _showErrorToast(context, "Unexpected data format.");
              return const Center(
                  child: Text("Invalid Firestore data format."));
            }

            final data = rawData; // Now safely casted

            final bikeType = data['bike_type'] as String? ?? 'Unknown';
            final timePrefs =
                (data['time_preferences'] as Map<String, dynamic>?) ?? {};
            final locationPrefs =
                (data['location_preferences'] as List<dynamic>?)
                        ?.whereType<String>()
                        .toList() ??
                    [];

            return Padding(
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
                    'WELCOME!',
                    style: TextStyle(
                      fontSize: 36,
                      color: Color(0xFFB22222),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'SEEMS LIKE YOU LOVE:',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryCard(bikeType),
                  const SizedBox(height: 20),
                  _buildPreferenceSection('To Ride During:', timePrefs),
                  const SizedBox(height: 20),
                  _buildPreferenceSection('In The:', locationPrefs),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A1818),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'START',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showErrorToast(BuildContext context, String message) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: const Text('Error'),
          subtitle: Text(message),
          leading: const Icon(Icons.error, color: Colors.red),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  Widget _buildSummaryCard(String bikeType) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/${bikeType.toLowerCase()}.png',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.directions_bike,
                  size: 100, color: Colors.grey);
            },
          ),
          const SizedBox(height: 8),
          Text(
            bikeType,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection(String title, dynamic preferences) {
    List<String> selectedPreferences = [];

    if (preferences is Map<String, dynamic>) {
      // If it's a Map, extract keys where the value is 'true'
      selectedPreferences = preferences.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();
    } else if (preferences is List<dynamic>) {
      // If it's a List, safely cast it to List<String>
      selectedPreferences = preferences.whereType<String>().toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: selectedPreferences.map((pref) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(pref),
            );
          }).toList(),
        ),
      ],
    );
  }
}
