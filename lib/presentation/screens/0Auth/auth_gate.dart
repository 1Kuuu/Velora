import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velora/presentation/intro/what_screen.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/1Home/home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        String uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData ||
                !(userSnapshot.data?.exists ?? false)) {
              return const WhatScreen();
            }

            var userData = userSnapshot.data?.data() as Map<String, dynamic>?;

            if (userData == null || userData['user_preference'] == null) {
              return const WhatScreen();
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
