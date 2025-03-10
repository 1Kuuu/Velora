import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'dart:io';
import 'package:velora/data/sources/firebase_service.dart'; // Import FirebaseServices
import 'package:velora/data/sources/post_service.dart'; // Import PostService
import 'package:velora/presentation/widgets/reusable_wdgts.dart'; // Import reusable widgets

class ProfilePage extends StatefulWidget {
  final String? userId;
  final bool isFollowing;
  final Function(bool)? onFollowChanged;

  const ProfilePage({
    super.key,
    this.userId,
    this.isFollowing = false,
    this.onFollowChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  bool isCurrentUser = false;
  bool isFollowing = false;
  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> posts = [];
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _mediaFiles = [];

  @override
  void initState() {
    super.initState();
    isFollowing = widget.isFollowing;
    _loadData();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Check if user is logged in
      if (FirebaseServices.currentUserId == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      String targetUserId = widget.userId ?? FirebaseServices.currentUserId!;
      isCurrentUser = targetUserId == FirebaseServices.currentUserId;

      // Fetch user data from the correct collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Using the correct collection name
          .doc(targetUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userData = {
            'userId': targetUserId,
            'userName': data['userName'] ??
                data['name'] ??
                data['email']?.split('@')[0] ??
                'Unknown User',
            'email': data['email'] ?? '',
            'bio': data['bio'] ?? 'No bio available',
            'profileUrl': data['profileUrl'] ?? '',
            'followers': data['followers'] ?? [],
            'following': data['following'] ?? [],
            'followerCount': (data['followers'] as List?)?.length ?? 0,
            'followingCount': (data['following'] as List?)?.length ?? 0,
            'postsCount': data['postsCount'] ?? 0,
            'activitiesCount': data['activitiesCount'] ?? 0,
            'createdAt': data['createdAt'],
          };
        });

        // Check if current user is following this profile
        if (!isCurrentUser && FirebaseServices.currentUserId != null) {
          List<dynamic> followers = data['followers'] ?? [];
          setState(() {
            isFollowing = followers.contains(FirebaseServices.currentUserId);
          });
        }

        // Fetch posts for the profile
        QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: targetUserId)
            .orderBy('createdAt', descending: true)
            .get();

        List<Map<String, dynamic>> userPosts = [];
        for (var doc in postsSnapshot.docs) {
          Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;

          // Get comments count
          QuerySnapshot commentsSnapshot =
              await doc.reference.collection('comments').get();
          int commentsCount = commentsSnapshot.docs.length;

          // Check if current user has liked this post
          bool isLiked = false;
          if (FirebaseServices.currentUserId != null) {
            DocumentSnapshot likeDoc = await doc.reference
                .collection('likes')
                .doc(FirebaseServices.currentUserId)
                .get();
            isLiked = likeDoc.exists;
          }

          userPosts.add({
            ...postData,
            'id': doc.id,
            'isLiked': isLiked,
            'commentsCount': commentsCount,
          });
        }

        setState(() {
          posts = userPosts;
        });
      } else {
        _showToast('User profile not found', isError: true);
      }
    } catch (e) {
      print('Error loading profile data: $e');
      _showToast('Error loading profile: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;
    setState(() => isLoading = true);
    try {
      if (FirebaseServices.currentUserId == null) return;

      // Get target user's document
      DocumentSnapshot targetUserDoc = await FirebaseFirestore.instance
          .collection('users') // Changed to 'users' collection
          .doc(widget.userId)
          .get();

      if (!targetUserDoc.exists) {
        throw Exception('User profile not found');
      }

      // Get current user's document
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users') // Changed to 'users' collection
          .doc(FirebaseServices.currentUserId)
          .get();

      if (!currentUserDoc.exists) {
        throw Exception('Current user profile not found');
      }

      Map<String, dynamic> targetUserData =
          targetUserDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> currentUserData =
          currentUserDoc.data() as Map<String, dynamic>;

      List<dynamic> targetUserFollowers =
          List.from(targetUserData['followers'] ?? []);
      List<dynamic> currentUserFollowing =
          List.from(currentUserData['following'] ?? []);

      // Update followers and following lists
      if (isFollowing) {
        targetUserFollowers.remove(FirebaseServices.currentUserId);
        currentUserFollowing.remove(widget.userId);
      } else {
        targetUserFollowers.add(FirebaseServices.currentUserId);
        currentUserFollowing.add(widget.userId);
      }

      // Update target user's followers
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'followers': targetUserFollowers,
      });

      // Update current user's following
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseServices.currentUserId)
          .update({
        'following': currentUserFollowing,
      });

      setState(() {
        isFollowing = !isFollowing;
        userData['followers'] = targetUserFollowers;
        userData['followerCount'] = targetUserFollowers.length;
      });

      // Call the onFollowChanged callback if provided
      widget.onFollowChanged?.call(isFollowing);

      _showToast(isFollowing ? 'Started following' : 'Unfollowed');
    } catch (e) {
      print('Error toggling follow: $e');
      _showToast('Failed to update follow status', isError: true);
    } finally {
      setState(() => isLoading = false);
      await _loadData(); // Reload data to refresh the UI
    }
  }

  Future<void> _pickMedia(bool isImage) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file != null) {
        setState(() => _mediaFiles.add(File(file.path)));
      }
    } catch (e) {
      _showToast('Failed to pick media: $e', isError: true);
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _mediaFiles.isEmpty) {
      _showToast('Please add some content to your post', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      if (FirebaseServices.currentUserId == null) return;

      // Get current user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(FirebaseServices.userCollection)
          .doc(FirebaseServices.currentUserId)
          .get();

      if (!userDoc.exists) {
        _showToast('User profile not found', isError: true);
        return;
      }

      Map<String, dynamic> currentUserData =
          userDoc.data() as Map<String, dynamic>;

      // Create post document
      await FirebaseFirestore.instance
          .collection(PostService.postsCollection)
          .add({
        'content': _postController.text.trim(),
        'userId': FirebaseServices.currentUserId,
        'authorId': FirebaseServices.currentUserId,
        'authorName': currentUserData['userName'] ?? 'Anonymous',
        'authorAvatar': currentUserData['profileUrl'] ?? '',
        'authorEmail': currentUserData['email'] ?? '',
        'mediaUrl': '',
        'mediaType': 'none',
        'likesCount': 0,
        'commentsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _postController.clear();
      setState(() => _mediaFiles.clear());

      await _loadData(); // Refresh the posts
      _showToast('Post created successfully');
    } catch (e) {
      print('Error creating post: $e');
      _showToast('Failed to create post: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _likePost(String postId) async {
    if (postId.isEmpty || FirebaseServices.currentUserId == null) {
      _showToast('Cannot like post at this time', isError: true);
      return;
    }

    try {
      DocumentReference postRef = FirebaseFirestore.instance
          .collection(PostService.postsCollection)
          .doc(postId);
      DocumentReference likeRef = postRef
          .collection(PostService.likesCollection)
          .doc(FirebaseServices.currentUserId);

      DocumentSnapshot likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike the post
        await likeRef.delete();
        await postRef.update({'likesCount': FieldValue.increment(-1)});
        _showToast('Post unliked');
      } else {
        // Like the post
        await likeRef.set({
          'userId': FirebaseServices.currentUserId,
          'timestamp': FieldValue.serverTimestamp()
        });
        await postRef.update({'likesCount': FieldValue.increment(1)});
        _showToast('Post liked');
      }

      await _loadData(); // Refresh the posts to update UI
    } catch (e) {
      print('Error liking post: $e');
      _showToast('Failed to update like status', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: Text(message),
          leading: Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Colors.red : Colors.green,
          ),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 300),
    ).show(context);
  }

  void _navigateToEditProfile() async {
    try {
      var freshUserDoc =
          await FirebaseServices.getUserData(FirebaseServices.currentUserId!);
      if (freshUserDoc != null && freshUserDoc.exists) {
        setState(() {
          userData = freshUserDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      _showToast('Error refreshing user data: $e', isError: true);
    }

    Map<String, dynamic> profileData = {
      'name': userData['userName'] ?? userData['name'] ?? '',
      'bio': userData['bio'] ?? '',
      'profileUrl': userData['profileUrl'] ?? '',
    };

    final result = await Navigator.pushNamed(
      context,
      '/edit-profile',
      arguments: profileData,
    );

    if (result != null) {
      await _loadData();
      _showToast('Profile updated successfully');
    }
  }

  Future<void> _showComments(String postId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: AppFonts.bold.copyWith(fontSize: 20),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading comments'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No comments yet'));
                  }

                  return ListView.builder(
                    controller: controller,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var comment = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment['userProfileUrl'] != null &&
                                  comment['userProfileUrl']
                                      .toString()
                                      .isNotEmpty
                              ? NetworkImage(comment['userProfileUrl'])
                              : null,
                          child: comment['userProfileUrl'] == null ||
                                  comment['userProfileUrl'].toString().isEmpty
                              ? Text(
                                  (comment['userName'] ?? 'U')[0].toUpperCase())
                              : null,
                        ),
                        title: Text(comment['userName'] ?? 'Unknown User'),
                        subtitle: Text(comment['content'] ?? ''),
                        trailing: Text(_formatTimestamp(comment['timestamp'])),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 8,
                right: 8,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (content) async {
                        if (content.trim().isEmpty) return;
                        try {
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .collection('comments')
                              .add({
                            'content': content.trim(),
                            'userId': FirebaseServices.currentUserId,
                            'userName': userData['userName'],
                            'userProfileUrl': userData['profileUrl'],
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          // Update comments count in the post
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .update({
                            'commentsCount': FieldValue.increment(1),
                          });
                        } catch (e) {
                          _showToast('Failed to add comment: $e',
                              isError: true);
                        }
                      },
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: MyAppBar(
        title: "Profile",
        actions: isCurrentUser
            ? [
                IconButton(
                    icon: Icon(Icons.edit, color: theme.colorScheme.onSurface),
                    onPressed: _navigateToEditProfile),
                IconButton(
                    icon: Icon(Icons.settings,
                        color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pushNamed(context, '/settings')),
              ]
            : [],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildProfileHeader(),
                  _buildProfileStats(),
                  if (isCurrentUser) _buildPostCreation(),
                  _buildPostsSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: userData['profileUrl'] != null &&
                    userData['profileUrl'].toString().isNotEmpty
                ? NetworkImage(userData['profileUrl'])
                : null,
            child: userData['profileUrl'] == null ||
                    userData['profileUrl'].toString().isEmpty
                ? Icon(Icons.person,
                    size: 60, color: theme.colorScheme.onSurface)
                : null,
          ),
          const SizedBox(height: 16),
          Text(userData['userName'] ?? 'User Name',
              style: AppFonts.bold
                  .copyWith(fontSize: 22, color: theme.colorScheme.onSurface)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Text(
              userData['bio'] ?? 'No bio available',
              style: AppFonts.medium.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ),
          if (!isCurrentUser) _buildInteractionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    final theme = Theme.of(context);
    final followingCount = (userData['following'] as List?)?.length ?? 0;
    final followersCount = (userData['followers'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () => _showFollowList(
                context, 'Following', userData['following'] ?? []),
            child: _buildStat('Following', followingCount.toString(), theme),
          ),
          InkWell(
            onTap: () => _showFollowList(
                context, 'Followers', userData['followers'] ?? []),
            child: _buildStat('Followers', followersCount.toString(), theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value,
            style: AppFonts.bold
                .copyWith(fontSize: 20, color: theme.colorScheme.onPrimary)),
        Text(label,
            style: AppFonts.medium
                .copyWith(color: theme.colorScheme.onPrimary, fontSize: 14)),
      ],
    );
  }

  Widget _buildInteractionButtons() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _toggleFollow,
          icon: Icon(isFollowing ? Icons.check : Icons.person_add_outlined),
          label: Text(isFollowing ? 'Following' : 'Follow'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing
                ? theme.colorScheme.surface
                : theme.colorScheme.primary,
            foregroundColor: isFollowing
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onPrimary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildPostCreation() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Post',
              style: AppFonts.bold
                  .copyWith(fontSize: 20, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 3,
                    style: AppFonts.medium
                        .copyWith(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: AppFonts.medium.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                  ),
                  if (_mediaFiles.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mediaFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: _mediaFiles[index].path.endsWith('.mp4')
                                    ? Icon(Icons.videocam,
                                        size: 80,
                                        color: theme.colorScheme.error)
                                    : Image.file(_mediaFiles[index],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _mediaFiles.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(Icons.close,
                                        size: 16,
                                        color: theme.colorScheme.onError),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.image,
                                color: theme.colorScheme.primary),
                            onPressed: () => _pickMedia(true),
                          ),
                          IconButton(
                            icon: Icon(Icons.videocam,
                                color: theme.colorScheme.error),
                            onPressed: () => _pickMedia(false),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Post', style: AppFonts.medium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Posts',
              style: AppFonts.bold
                  .copyWith(fontSize: 20, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          if (posts.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.feed_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text('No posts yet',
                      style: AppFonts.medium.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            )
          else
            ...posts.map((post) => _buildPostCard(post)),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final bool isLiked = post['isLiked'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: userData['profileUrl'] != null &&
                          userData['profileUrl'].toString().isNotEmpty
                      ? NetworkImage(userData['profileUrl'])
                      : null,
                  child: userData['profileUrl'] == null ||
                          userData['profileUrl'].toString().isEmpty
                      ? Icon(Icons.person,
                          size: 20, color: theme.colorScheme.onSurface)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['userName'] ?? 'User',
                          style: AppFonts.bold.copyWith(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface)),
                      Text(_formatTimestamp(post['createdAt']),
                          style: AppFonts.medium.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5))),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  IconButton(
                    icon: Icon(Icons.more_vert,
                        color: theme.colorScheme.onSurface),
                    onPressed: () => _showPostOptions(post),
                  ),
              ],
            ),
            if (post['content'] != null &&
                post['content'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(post['content'] ?? '',
                    style: AppFonts.medium.copyWith(
                        fontSize: 16, color: theme.colorScheme.onSurface)),
              ),
            if (post['mediaUrl'] != null &&
                post['mediaUrl'].toString().isNotEmpty)
              _buildPostImage(post['mediaUrl']),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showLikesList(context, post['id']),
                    child: Text('${post['likesCount'] ?? 0} likes',
                        style: AppFonts.medium.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5))),
                  ),
                  const SizedBox(width: 16),
                  Text('${post['commentsCount'] ?? 0} comments',
                      style: AppFonts.medium.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            Divider(height: 24, color: theme.dividerColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPostAction(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: isLiked
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  onTap: () => _likePost(post['id']),
                ),
                _buildPostAction(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  onTap: () => _showComments(post['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: theme.colorScheme.onSurface),
              title: Text('Edit Post',
                  style: AppFonts.medium
                      .copyWith(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _showToast('Edit post functionality coming soon');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text('Delete Post',
                  style:
                      AppFonts.medium.copyWith(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePost(post['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(String postId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Delete Post',
            style: AppFonts.bold.copyWith(color: theme.colorScheme.onSurface)),
        content: Text('Are you sure you want to delete this post?',
            style:
                AppFonts.medium.copyWith(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    AppFonts.medium.copyWith(color: theme.colorScheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection(PostService.postsCollection)
                    .doc(postId)
                    .delete();
                _showToast('Post deleted successfully');
                await _loadData();
              } catch (e) {
                _showToast('Failed to delete post: $e', isError: true);
              }
            },
            child: Text(
              'Delete',
              style: AppFonts.medium.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildPostAction({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey, size: 20),
            const SizedBox(width: 4),
            Text(label,
                style: AppFonts.medium.copyWith(color: color ?? Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'Recently';
      }
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return DateFormat('EEEE').format(dateTime);
    if (difference.inDays < 365) return DateFormat('MMM d').format(dateTime);
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  void _showFollowList(
      BuildContext context, String title, List<dynamic> userIds) {
    final theme = Theme.of(context);
    if (userIds.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(title,
              style: AppFonts.bold
                  .copyWith(fontSize: 20, color: theme.colorScheme.onSurface)),
          content: Text('No $title yet',
              style:
                  AppFonts.medium.copyWith(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: AppFonts.medium
                      .copyWith(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.surface,
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: AppFonts.bold.copyWith(
                      fontSize: 20, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(FirebaseServices.userCollection)
                        .where(FieldPath.documentId, whereIn: userIds)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text('No $title found',
                              style: AppFonts.medium.copyWith(
                                  color: theme.colorScheme.onSurface)),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var userData = snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                          var userId = snapshot.data!.docs[index].id;
                          return ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfilePage(userId: userId),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                backgroundImage:
                                    userData['profileUrl'] != null &&
                                            userData['profileUrl']
                                                .toString()
                                                .isNotEmpty
                                        ? NetworkImage(userData['profileUrl'])
                                        : null,
                                child: userData['profileUrl'] == null ||
                                        userData['profileUrl']
                                            .toString()
                                            .isEmpty
                                    ? Text(
                                        (userData['userName'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: theme.colorScheme.onSurface),
                                      )
                                    : null,
                              ),
                            ),
                            title: Text(
                              userData['userName'] ?? 'Unknown User',
                              style: AppFonts.medium
                                  .copyWith(color: theme.colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              userData['bio'] ?? 'No bio',
                              style: AppFonts.medium.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProfilePage(userId: userId),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close',
                    style: AppFonts.medium
                        .copyWith(color: theme.colorScheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLikesList(BuildContext context, String postId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.surface,
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Likes',
                  style: AppFonts.bold.copyWith(
                      fontSize: 20, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 16),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(PostService.postsCollection)
                        .doc(postId)
                        .collection(PostService.likesCollection)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text('No likes yet',
                              style: AppFonts.medium.copyWith(
                                  color: theme.colorScheme.onSurface)),
                        );
                      }

                      List<String> userIds = snapshot.data!.docs
                          .map((doc) => doc['userId'] as String)
                          .toList();

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(FirebaseServices.userCollection)
                            .where(FieldPath.documentId, whereIn: userIds)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!userSnapshot.hasData ||
                              userSnapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text('No user data found',
                                  style: AppFonts.medium.copyWith(
                                      color: theme.colorScheme.onSurface)),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: userSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var userData = userSnapshot.data!.docs[index]
                                  .data() as Map<String, dynamic>;
                              var userId = userSnapshot.data!.docs[index].id;

                              return ListTile(
                                leading: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfilePage(userId: userId),
                                      ),
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundImage: userData['profileUrl'] !=
                                                null &&
                                            userData['profileUrl']
                                                .toString()
                                                .isNotEmpty
                                        ? NetworkImage(userData['profileUrl'])
                                        : null,
                                    child: userData['profileUrl'] == null ||
                                            userData['profileUrl']
                                                .toString()
                                                .isEmpty
                                        ? Text(
                                            (userData['userName'] ?? 'U')[0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                                color: theme
                                                    .colorScheme.onSurface),
                                          )
                                        : null,
                                  ),
                                ),
                                title: Text(
                                  userData['userName'] ?? 'Unknown User',
                                  style: AppFonts.medium.copyWith(
                                      color: theme.colorScheme.onSurface),
                                ),
                                subtitle: Text(
                                  userData['bio'] ?? 'No bio',
                                  style: AppFonts.medium.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfilePage(userId: userId),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close',
                    style: AppFonts.medium
                        .copyWith(color: theme.colorScheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
