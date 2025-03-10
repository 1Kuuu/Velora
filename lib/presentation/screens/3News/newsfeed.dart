import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:velora/core/configs/theme/app_colors.dart';
import 'package:velora/core/configs/theme/app_fonts.dart';
import 'package:velora/core/configs/theme/theme_provider.dart';
import 'package:velora/data/sources/post_service.dart';
import 'package:velora/presentation/screens/0Auth/profile.dart';
import 'package:velora/presentation/screens/3News/search_view.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:provider/provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';

class NewsFeedPageContent extends StatefulWidget {
  const NewsFeedPageContent({super.key});

  @override
  _NewsFeedPageContentState createState() => _NewsFeedPageContentState();
}

class _NewsFeedPageContentState extends State<NewsFeedPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : AppColors.lightBackground,
      appBar: MyAppBar(
        title: "Velora",
        actions: [
          AppBarIcon(
            icon: Icons.search,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchView()),
            ),
          ),
          AppBarIcon(
            icon: Icons.notifications_outlined,
            onTap: () => print("Notifications Tapped"),
          ),
          AppBarIcon(
            icon: Icons.person_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // "What's on your mind?" input field
          PostInputField(),
          // Following/Discover tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Following"),
                Tab(text: "Discover"),
              ],
              labelColor: isDarkMode ? Colors.white : AppColors.primary,
              unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.grey,
              indicatorColor: isDarkMode ? Colors.white : AppColors.primary,
              labelStyle: AppFonts.bold.copyWith(fontSize: 16),
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                NewsFeedList(tab: "Following"),
                NewsFeedList(tab: "Discover"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostInputField extends StatefulWidget {
  const PostInputField({super.key});

  @override
  _PostInputFieldState createState() => _PostInputFieldState();
}

class _PostInputFieldState extends State<PostInputField> {
  final TextEditingController _controller = TextEditingController();
  File? _image;
  File? _video;
  final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      print('Text changed: "${_controller.text}"');
      setState(() {}); // Rebuild widget when text changes
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _video = null; // Clear video when image is selected
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration:
          const Duration(minutes: 5), // Limit video duration to 5 minutes
    );
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
        _image = null; // Clear image when video is selected
      });
    }
  }

  Future<void> _postRide() async {
    print('Attempting to post with text: "${_controller.text}"');
    if (user == null || _controller.text.trim().isEmpty) {
      print(
          'Post cancelled - user: ${user != null}, text empty: ${_controller.text.trim().isEmpty}');
      return;
    }

    final postId = await PostService.createPost(
      content: _controller.text,
      image: _image,
      video: _video,
      rideData: {
        'route': 'Sample Route',
        'distance': 10.5,
        'duration': '1h 30m',
      },
    );

    if (postId != null) {
      print('Post created successfully with ID: $postId');
      _controller.clear();
      setState(() {
        _image = null;
        _video = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user?.photoURL ?? ''),
                radius: 20,
                backgroundColor:
                    isDarkMode ? Colors.grey[800] : Colors.grey[300],
                child: user?.photoURL == null
                    ? Icon(Icons.person,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600])
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  style: AppFonts.regular.copyWith(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: AppFonts.regular.copyWith(
                      color: isDarkMode ? Colors.white60 : Colors.grey[500],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          if (_image != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_video != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black87,
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.video_file, size: 64, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _video = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.image,
                            color:
                                isDarkMode ? Colors.white : AppColors.primary),
                        label: Text(
                          'Photo',
                          style: AppFonts.medium.copyWith(
                            color:
                                isDarkMode ? Colors.white : AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          backgroundColor: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _pickVideo,
                        icon: Icon(Icons.videocam,
                            color:
                                isDarkMode ? Colors.white : AppColors.primary),
                        label: Text(
                          'Video',
                          style: AppFonts.medium.copyWith(
                            color:
                                isDarkMode ? Colors.white : AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          backgroundColor: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _controller.text.trim().isEmpty ? null : _postRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? const Color(0xFF4A3B7C)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Post',
                    style: AppFonts.semibold.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NewsFeedList extends StatelessWidget {
  final String tab;
  const NewsFeedList({required this.tab, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: PostService.getPostsStream(tab: tab),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error loading posts: ${snapshot.error}');
          return Center(
            child: Text(
              "Error loading posts. Please try again.",
              style: AppFonts.medium.copyWith(color: Colors.grey),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          if (tab == "Following") {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Follow people to see their posts here!",
                    style: AppFonts.medium.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No posts yet. Be the first to post!",
                  style: AppFonts.medium.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs.toList();

        // Sort and filter posts based on tab
        if (tab == "Discover") {
          // Mark posts as viewed when they are rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (var post in posts) {
              PostService.markPostAsViewed(post.id).then((_) {
                print('Successfully marked post ${post.id} as viewed');
              }).catchError((error) {
                print('Error marking post ${post.id} as viewed: $error');
              });
            }
          });
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => RideFeedItem(ride: posts[index]),
        );
      },
    );
  }
}

class RideFeedItem extends StatefulWidget {
  final QueryDocumentSnapshot ride;
  const RideFeedItem({required this.ride, super.key});

  @override
  _RideFeedItemState createState() => _RideFeedItemState();
}

class _RideFeedItemState extends State<RideFeedItem> {
  late String postId;
  bool isLiked = false;
  final user = FirebaseAuth.instance.currentUser;
  bool _showComments = false;
  Map<String, dynamic>? authorData;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    postId = widget.ride.id;
    _checkIfLiked();
    _loadAuthorData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthorData() async {
    final postData = widget.ride.data() as Map<String, dynamic>;
    final authorId = postData['authorId'];
    if (authorId != null) {
      final userData = await PostService.getUserData(authorId);
      if (mounted) {
        setState(() => authorData = userData);
      }
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }

  Future<void> _checkIfLiked() async {
    final liked = await PostService.isLikedByUser(postId);
    if (mounted) setState(() => isLiked = liked);
  }

  Future<void> _toggleLike() async {
    final success = await PostService.toggleLike(postId);
    if (mounted) setState(() => isLiked = success);
  }

  Future<void> _deletePost() async {
    final success = await PostService.deletePost(postId);
    if (success) {
      DelightToastBar(
        builder: (context) {
          return const ToastCard(
            title: Text('Post deleted successfully'),
            leading: Icon(Icons.check_circle, color: Colors.green),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    var postData = widget.ride.data() as Map<String, dynamic>;
    String content = postData['content'] ?? '';
    String? mediaUrl = postData['mediaUrl'];
    String mediaType = postData['mediaType'] ?? 'none';
    Map<String, dynamic>? rideData = postData['rideData'];
    int likesCount = postData['likesCount'] ?? 0;
    int commentsCount = postData['commentsCount'] ?? 0;
    String userId = postData['userId'] ?? '';

    // Use author data from Firestore if available
    String authorName =
        authorData?['userName'] ?? postData['authorName'] ?? 'Anonymous';
    String authorAvatar =
        authorData?['profileUrl'] ?? postData['authorAvatar'] ?? '';
    String authorEmail = authorData?['email'] ?? postData['authorEmail'] ?? '';

    return Card(
      margin: const EdgeInsets.all(12.0),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: isDarkMode ? 0 : 5,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(userId),
                  child: CircleAvatar(
                    backgroundImage: authorAvatar.isNotEmpty
                        ? NetworkImage(authorAvatar)
                        : null,
                    radius: 22,
                    backgroundColor: Colors.grey[300],
                    child: authorAvatar.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(userId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: AppFonts.bold.copyWith(fontSize: 16),
                        ),
                        if (authorEmail.isNotEmpty)
                          Text(
                            authorEmail,
                            style: AppFonts.regular.copyWith(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          _formatTimestamp(postData['timestamp'] as Timestamp?),
                          style: AppFonts.regular.copyWith(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (userId == user?.uid)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPostOptions(context),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  content,
                  style: AppFonts.medium.copyWith(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            if (mediaUrl != null && mediaUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: mediaType == 'video'
                      ? Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 64,
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Text(
                                  'Tap to play video',
                                  style: AppFonts.medium.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            );
                          },
                        ),
                ),
              ),
            if (rideData != null) ...[
              const SizedBox(height: 12),
              Text(
                "Route: ${rideData['route']}",
                style: AppFonts.regular.copyWith(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                "Distance: ${rideData['distance']} km",
                style: AppFonts.regular.copyWith(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                "Duration: ${rideData['duration']}",
                style: AppFonts.regular.copyWith(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "$likesCount ${likesCount == 1 ? 'like' : 'likes'}",
                  style: AppFonts.regular.copyWith(
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.hasData ? snapshot.data!.size : commentsCount;
                    return Text(
                      "$count ${count == 1 ? 'comment' : 'comments'}",
                      style: AppFonts.regular.copyWith(
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
            Divider(
              height: 24,
              color: isDarkMode ? Colors.white24 : Colors.grey[300],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'Like',
                    color: isLiked ? Colors.red : Colors.grey,
                    onTap: _toggleLike,
                  ),
                ),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    onTap: () => setState(() => _showComments = !_showComments),
                  ),
                ),
              ],
            ),
            if (_showComments) ...[
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle:
                              AppFonts.regular.copyWith(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        if (_commentController.text.trim().isEmpty) return;

                        final success = await PostService.addComment(
                            postId, _commentController.text);
                        _commentController.clear(); // Clear the text field
                      },
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              CommentsSection(postId: postId, onDeleteComment: _deleteComment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(label,
                style: AppFonts.medium.copyWith(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Post'),
            onTap: () {
              Navigator.pop(context);
              _deletePost();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Post'),
            onTap: () async {
              Navigator.pop(context);
              final postData = widget.ride.data() as Map<String, dynamic>;
              final TextEditingController contentController =
                  TextEditingController(text: postData['content']);

              final bool? result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Post'),
                  content: TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      hintText: 'Edit your post...',
                    ),
                    maxLines: null,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );

              if (result == true && contentController.text.trim().isNotEmpty) {
                final success = await PostService.updatePost(
                    postId, contentController.text.trim());
                if (success && mounted) {
                  DelightToastBar(
                    builder: (context) {
                      return const ToastCard(
                        title: Text('Post updated successfully'),
                        leading: Icon(Icons.check_circle, color: Colors.green),
                      );
                    },
                    position: DelightSnackbarPosition.top,
                    autoDismiss: true,
                    snackbarDuration: const Duration(seconds: 2),
                    animationDuration: const Duration(milliseconds: 300),
                  ).show(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final success = await PostService.deleteComment(postId, commentId);
  }
}

class CommentsSection extends StatefulWidget {
  final String postId;
  final Function(String) onDeleteComment;

  const CommentsSection(
      {required this.postId, required this.onDeleteComment, super.key});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  Stream<QuerySnapshot>? _commentsStream;

  @override
  void initState() {
    super.initState();
    try {
      _commentsStream = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .limit(50) // Add a reasonable limit
          .snapshots();
    } catch (e) {
      print('Error initializing comments stream: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: _commentsStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          print('Comments stream error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Error loading comments. Please try again later.'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No comments yet. Be the first to comment!'),
          );
        }

        final comments = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;

            // If either timestamp is null, put it at the end
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;

            return bTimestamp.compareTo(aTimestamp); // Sort newest first
          });

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  var comment = comments[index];
                  var data = comment.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfilePage(userId: data['userId']),
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage:
                              data['userAvatar']?.isNotEmpty == true
                                  ? NetworkImage(data['userAvatar'])
                                  : null,
                          backgroundColor: Colors.grey[300],
                          child: data['userAvatar']?.isEmpty ?? true
                              ? Icon(Icons.person, color: Colors.grey[600])
                              : null,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProfilePage(userId: data['userId']),
                                ),
                              ),
                              child: Text(
                                data['userName'] ?? 'Anonymous',
                                style: AppFonts.bold.copyWith(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(data['timestamp'] as Timestamp?),
                            style: AppFonts.regular.copyWith(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        data['text'] ?? '',
                        style: AppFonts.regular.copyWith(fontSize: 14),
                      ),
                      trailing: data['userId'] == currentUser?.uid
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _confirmDeleteComment(
                                context,
                                comment.id,
                                data['text'] ?? '',
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Show confirmation dialog before deleting comment
  Future<void> _confirmDeleteComment(
      BuildContext context, String commentId, String commentText) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment?', style: AppFonts.bold),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this comment?',
                  style: AppFonts.regular),
              const SizedBox(height: 8),
              Text(
                commentText,
                style: AppFonts.regular.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppFonts.medium.copyWith(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: AppFonts.medium.copyWith(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await widget.onDeleteComment(commentId);
    }
  }
}
