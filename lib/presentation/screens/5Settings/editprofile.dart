import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  String? _profileImageUrl;
  File? _imageFile;
  String? _originalName;
  String? _originalBio;
  bool _imageChanged = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MyAppBar(
        title: "Edit Profile",
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 75,
                                backgroundColor: theme.colorScheme.surface,
                                backgroundImage: _getProfileImage(),
                                child: _getProfileImage() == null
                                    ? Icon(Icons.person,
                                        size: 70,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5))
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.camera_alt,
                                      size: 20,
                                      color: theme.colorScheme.onPrimary),
                                  onPressed: () => _pickImage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(26.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Personal Information",
                              style: AppFonts.bold.copyWith(
                                fontSize: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          "Name",
                          _nameController,
                          "Enter your name",
                          Icons.person_outline,
                          theme,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          "Bio",
                          _bioController,
                          "Write something about yourself",
                          Icons.description_outlined,
                          theme,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 36),
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: CustomButton(
                              text: "Save Changes",
                              onPressed: _handleUpdateProfile,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
    ThemeData theme, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.semibold.copyWith(
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: AppFonts.regular.copyWith(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppFonts.regular.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              prefixIcon: Icon(icon, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showToast(String message, IconData icon, Color color) {
    DelightToastBar(
      builder: (context) => ToastCard(
        title: Text('Notification',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        leading: Icon(icon, color: color),
        subtitle: Text(message, style: const TextStyle(fontSize: 14)),
      ),
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: Durations.extralong4,
    ).show(context);
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    print("Loading user data..."); // Debug print

    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      print("Loading data from arguments: $args"); // Debug print
      setState(() {
        _originalName = args['name'] ?? '';
        _originalBio = args['bio'] ?? '';
        _profileImageUrl = args['profileUrl'];
        _nameController.text = _originalName!;
        _bioController.text = _originalBio!;
        _isLoading = false;
      });
      return;
    }

    User? user = _auth.currentUser;
    print("Current user: ${user?.email}"); // Debug print

    if (user != null) {
      try {
        // First set basic user info from Firebase Auth
        setState(() {
          _profileImageUrl = user.photoURL;
          _nameController.text = user.displayName ?? '';
          _originalName = user.displayName ?? '';
        });

        // Then fetch additional info from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        print("Firestore data exists: ${userDoc.exists}"); // Debug print

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          print("Fetched Firestore data: $data"); // Debug print

          setState(() {
            _originalName = data['userName'] ?? user.displayName ?? '';
            _originalBio = data['bio'] ?? '';
            _profileImageUrl = data['profileUrl'] ?? user.photoURL;
            _nameController.text = _originalName!;
            _bioController.text = _originalBio!;
          });
        } else {
          // If document doesn't exist, create it with default values
          await _firestore.collection('users').doc(user.uid).set({
            'userName': user.displayName ?? '',
            'email': user.email ?? '',
            'bio': '',
            'profileUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _originalName = user.displayName ?? '';
            _originalBio = '';
            _nameController.text = _originalName!;
            _bioController.text = '';
          });
        }
      } catch (e) {
        print("Error loading user data: $e"); // Debug print
        _showToast("Error loading user data: $e", Icons.error, Colors.red);
      }
    } else {
      _showToast("No user logged in", Icons.error, Colors.red);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    String newName = _nameController.text.trim();
    String newBio = _bioController.text.trim();

    if (newName.isEmpty || newBio.isEmpty) {
      _showToast("Fields cannot be empty!", Icons.warning, Colors.orange);
      return;
    }

    if (newName == _originalName && newBio == _originalBio && !_imageChanged) {
      _showToast("Nothing changed", Icons.info, Colors.blue);
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("User not found");

      String? updatedPhotoUrl = _profileImageUrl;

      if (_imageChanged && _imageFile != null) {
        final storageRef =
            FirebaseStorage.instance.ref().child('user_images/${user.uid}');
        final uploadTask = storageRef.putFile(_imageFile!);
        final snapshot = await uploadTask;
        updatedPhotoUrl = await snapshot.ref.getDownloadURL();
        await user.updatePhotoURL(updatedPhotoUrl);
      }

      // Update Firestore with all user data
      final userData = {
        'userName': newName,
        'email': user.email,
        'bio': newBio,
        'profileUrl': updatedPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).update(userData);

      // Update Firebase Auth display name
      await user.updateDisplayName(newName);

      setState(() {
        _originalName = newName;
        _originalBio = newBio;
        _profileImageUrl = updatedPhotoUrl;
        _imageChanged = false;
      });

      _showToast(
          "Profile updated successfully!", Icons.check_circle, Colors.green);

      // Pass back complete user data
      Navigator.pop(context, {
        'updated': true,
        'name': newName,
        'email': user.email,
        'bio': newBio,
        'profileUrl': updatedPhotoUrl,
        'uid': user.uid
      });
    } catch (e) {
      print("Error updating profile: $e"); // Debug print
      _showToast("Error updating profile: $e", Icons.error, Colors.red);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      _showToast("Error picking image: $e", Icons.error, Colors.red);
    }
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  void _handleUpdateProfile() {
    if (!_isLoading) {
      _updateProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
