import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/intro/onboarding.dart';
import 'package:velora/presentation/intro/welcome_screen.dart';
import 'package:velora/presentation/screens/1Home/home.dart'; // Ensure this import is correct and the HomePage class is defined in this file
import 'package:velora/presentation/screens/0Auth/signup.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/3News/newsfeed.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';
import 'package:velora/presentation/screens/5Settings/setting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const SplashScreen(), // Use the new splash screen
      routes: {
        '/getstarted': (context) => const GetStarted(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/settings': (context) => const SettingsScreen(), // ✅ Add this
        '/edit-profile': (context) => const EditProfileScreen(), // ✅ Add this
        '/newsfeed': (context) =>
            const NewsFeedPageContent(), // Add newsfeed route
      },
    );
  }
}

/// 🔹 Simple Splash Screen with app logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2)); // Show logo for 2 seconds
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 120,
        ),
      ),
    );
  }
}

/// 🔹 AuthWrapper to handle authentication and navigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage(); // 🚀 Not logged in? Go to Login
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final bool setupComplete = userData['setupComplete'] ?? false;

              if (setupComplete) {
                return const HomePage(); // 🏠 Go to HomePage after setup
              } else {
                return FutureBuilder<Widget>(
                  future: _checkLocalOnboarding(),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return futureSnapshot.data ?? const WelcomeScreen();
                  },
                );
              }
            } else {
              return FutureBuilder<Widget>(
                future: _checkLocalOnboarding(),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return futureSnapshot.data ?? const WelcomeScreen();
                },
              );
            }
          },
        );
      },
    );
  }

  /// 🔹 Check if onboarding was completed locally
  Future<Widget> _checkLocalOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    return onboardingComplete ? const HomePage() : const WelcomeScreen();
  }
}
