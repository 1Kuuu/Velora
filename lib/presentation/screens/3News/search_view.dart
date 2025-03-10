import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart' show MyAppBar;
import 'package:velora/presentation/screens/0Auth/profile.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  String searchName = "";
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'Search',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 40, left: 10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchName = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 39, 39, 39),
                  hintText: 'Search users...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildUserList(),
    );
  }

  /// 🔹 Extracted method for fetching and displaying users
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("No users found", style: TextStyle(color: Colors.grey)),
          );
        }

        var filteredUsers = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['userName'] ?? "").toLowerCase();
          return name.contains(searchName) && data['uid'] != currentUserId;
        }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Text("No matching users found",
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView(
          children: filteredUsers.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _buildUserTile(data);
          }).toList(),
        );
      },
    );
  }

  /// 🔹 Extracted method for rendering each user tile
  Widget _buildUserTile(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _generateRandomColor(data['userName']),
        backgroundImage: _hasProfilePicture(data['profileUrl'])
            ? NetworkImage(data['profileUrl'])
            : null,
        child: !_hasProfilePicture(data['profileUrl'])
            ? Text(
                _getInitials(data['userName']),
                style: const TextStyle(fontSize: 20, color: Colors.white),
              )
            : null,
      ),
      title: Text(data['userName'] ?? "Unknown User",
          style: TextStyle(color: theme.colorScheme.onSurface)),
      subtitle: Text(data['email'] ?? "No email available",
          style:
              TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: data['uid']),
          ),
        );
      },
    );
  }

  /// ✅ **Checks if a profile picture exists**
  bool _hasProfilePicture(String? url) {
    return url != null && url.isNotEmpty;
  }

  /// ✅ **Extracted logic to get initials**
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "?";
    return name[0].toUpperCase();
  }

  /// ✅ **Generates a random color based on username**
  Color _generateRandomColor(String? text) {
    return Colors.primaries[text!.hashCode.abs() % Colors.primaries.length];
  }
}
