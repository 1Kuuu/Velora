import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/screens/5Settings/editprofile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  User? user;
  Map<String, dynamic> userData = {
    'userName': 'Loading...',
    'email': 'Loading...',
    'bio': 'Loading...',
    'profileUrl': '',
  };
  bool isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          isDarkMode = prefs.getBool('isDarkMode') ?? false;
          isNotificationsEnabled =
              prefs.getBool('isNotificationsEnabled') ?? true;
        });
      }
    } catch (e) {
      print("Error loading preferences: $e");
    }
  }

  Future<void> _saveUserPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
      await prefs.setBool('isNotificationsEnabled', isNotificationsEnabled);

      // Save to Firebase if user is logged in
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'preferences': {
            'isDarkMode': isDarkMode,
            'isNotificationsEnabled': isNotificationsEnabled,
          }
        });
      }
    } catch (e) {
      print("Error saving preferences: $e");
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        setState(() {
          user = currentUser;
          isLoading = true;
        });

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userData = {
              'userName':
                  data['userName'] ?? currentUser.displayName ?? 'No Name',
              'email': data['email'] ?? currentUser.email ?? 'No Email',
              'bio': data['bio'] ?? 'No bio available',
              'profileUrl': data['profileUrl'] ?? currentUser.photoURL ?? '',
              'preferences': data['preferences'] ?? {},
            };

            // Update preferences if they exist in Firestore
            if (data['preferences'] != null) {
              isDarkMode = data['preferences']['isDarkMode'] ?? isDarkMode;
              isNotificationsEnabled = data['preferences']
                      ['isNotificationsEnabled'] ??
                  isNotificationsEnabled;
            }

            isLoading = false;
          });
        } else {
          // Create user document if it doesn't exist
          await _firestore.collection('users').doc(currentUser.uid).set({
            'userName': currentUser.displayName ?? 'No Name',
            'email': currentUser.email ?? 'No Email',
            'bio': 'No bio available',
            'profileUrl': currentUser.photoURL ?? '',
            'preferences': {
              'isDarkMode': isDarkMode,
              'isNotificationsEnabled': isNotificationsEnabled,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            setState(() {
              userData = {
                'userName': currentUser.displayName ?? 'No Name',
                'email': currentUser.email ?? 'No Email',
                'bio': 'No bio available',
                'profileUrl': currentUser.photoURL ?? '',
              };
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            userData = {
              'userName': 'No User Logged In',
              'email': '',
              'bio': 'Please log in to continue.',
              'profileUrl': '',
            };
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF4A3B7C)
              : AppColors.primary,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF121212)
          : AppColors.primary,
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          buildProfileSection(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  buildSectionTitle("Content"),
                  buildListTile(
                    icon: Icons.bookmark_border,
                    title: "Saved",
                    onTap: () {
                      Navigator.pushNamed(context, '/saved');
                    },
                  ),
                  buildToggleTile(
                    title: "Dark Mode",
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      await themeProvider.toggleTheme();
                      setState(() {
                        isDarkMode = themeProvider.isDarkMode;
                      });
                      _saveUserPreferences();
                    },
                    icon: Icons.dark_mode_outlined,
                  ),
                  buildToggleTile(
                    title: "Notification",
                    value: isNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        isNotificationsEnabled = value;
                      });
                      _saveUserPreferences();
                    },
                    icon: Icons.notifications_none,
                  ),
                  const SizedBox(height: 10),
                  buildSectionTitle("General"),
                  buildListTile(
                    icon: Icons.language,
                    title: "Language",
                    trailingText: "English",
                    onTap: () {
                      Navigator.pushNamed(context, '/language');
                    },
                  ),
                  buildListTile(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {
                      Navigator.pushNamed(context, '/help_support');
                    },
                  ),
                  buildListTile(
                    icon: Icons.description_outlined,
                    title: "Terms & Conditions",
                    onTap: () {
                      Navigator.pushNamed(context, '/terms_conditions');
                    },
                  ),
                  buildListTile(
                    icon: Icons.info_outline,
                    title: "About",
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                  buildListTile(
                    icon: Icons.logout,
                    title: "Logout",
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () {
                      _showLogoutConfirmationDialog(context);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _getProfileImage(),
                  child: _getProfileImage() == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            userData['userName'] ?? "User Name",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Color.fromARGB(100, 0, 0, 0),
                ),
              ],
            ),
          ),
          Text(
            userData['email'] ?? "No email",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2.0,
                  color: Color.fromARGB(70, 0, 0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            userData['bio'] ?? "No bio available",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2.0,
                  color: Color.fromARGB(70, 0, 0, 0),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                  settings: RouteSettings(
                    arguments: {
                      'name': userData['userName'],
                      'email': userData['email'],
                      'bio': userData['bio'],
                      'profileUrl': userData['profileUrl'],
                    },
                  ),
                ),
              );

              if (result != null && result['updated'] == true && mounted) {
                setState(() {
                  userData = {
                    'userName': result['name'],
                    'email': result['email'],
                    'bio': result['bio'],
                    'profileUrl': result['profileUrl'],
                  };
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 3,
            ),
            child: const Text(
              "Edit Profile",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (userData['profileUrl'] != null && userData['profileUrl'].isNotEmpty) {
      return NetworkImage(userData['profileUrl']);
    }
    return null;
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Logout",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            "Are you sure you want to log out?",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                "No",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                "Yes",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('hasCompletedOnboarding');
                await FirebaseAuth.instance.signOut();
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildListTile({
    required IconData icon,
    required String title,
    String? trailingText,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final defaultColor = themeProvider.isDarkMode ? Colors.white : Colors.black;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? defaultColor),
      title: Text(title, style: TextStyle(color: textColor ?? defaultColor)),
      trailing: trailingText != null
          ? Text(trailingText,
              style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey))
          : Icon(Icons.arrow_forward_ios,
              size: 16,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey),
      onTap: onTap,
    );
  }

  Widget buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final defaultColor = themeProvider.isDarkMode ? Colors.white : Colors.black;

    return ListTile(
      leading: Icon(icon, color: defaultColor),
      title: Text(title, style: TextStyle(color: defaultColor)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
