import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String postsCollection = 'posts';
  static const String likesCollection = 'likes';
  static const String commentsCollection = 'comments';
  static const String usersCollection = 'user_profile';
  static const String viewedPostsCollection = 'viewed_posts';

  // Get user data
  static Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final userDoc =
          await _firestore.collection(usersCollection).doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  // Create a new post
  static Future<String?> createPost({
    required String content,
    File? image,
    File? video,
    Map<String, dynamic>? rideData,
  }) async {
    try {
      print('Starting post creation...');
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user found');
        return null;
      }

      String? mediaUrl;
      String mediaType = 'none';

      if (image != null) {
        print('Uploading image...');
        final ref = _storage
            .ref()
            .child('post_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        mediaUrl = await ref.getDownloadURL();
        mediaType = 'image';
        print('Image uploaded successfully: $mediaUrl');
      } else if (video != null) {
        print('Uploading video...');
        final ref = _storage
            .ref()
            .child('post_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
        await ref.putFile(video);
        mediaUrl = await ref.getDownloadURL();
        mediaType = 'video';
        print('Video uploaded successfully: $mediaUrl');
      }

      print('Fetching user data...');
      final userData = await getUserData(user.uid);
      print('User data fetched: ${userData['userName']}');

      // Create post data matching exactly with rules requirements
      Map<String, dynamic> postData = {
        // Required fields
        'content': content.trim(),
        'userId': user.uid,
        'authorId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        // Optional fields with empty defaults
        'mediaUrl': mediaUrl ?? '',
        'mediaType': mediaType,
        'route': '',
        'distance': 0,
        'duration': '',
        'authorName': userData['userName'] ?? user.displayName ?? 'Anonymous',
        'authorAvatar': userData['profileUrl'] ?? user.photoURL ?? '',
        'authorEmail': userData['email'] ?? user.email ?? '',
      };

      print('Attempting to create post with data: $postData');
      final postRef =
          await _firestore.collection(postsCollection).add(postData);
      print('Post created successfully with ID: ${postRef.id}');

      print('Updating user post count...');
      await _firestore.collection(usersCollection).doc(user.uid).update({
        'postsCount': FieldValue.increment(1),
      });
      print('Post count updated successfully');

      return postRef.id;
    } catch (e) {
      print('Error creating post: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Delete a post
  static Future<bool> deletePost(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc =
          await _firestore.collection(postsCollection).doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      if (postData['userId'] != user.uid) return false;

      // Delete post image if exists
      if (postData['mediaUrl'] != null) {
        try {
          final ref = _storage.refFromURL(postData['mediaUrl']);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      // Delete post and its subcollections
      await _firestore.collection(postsCollection).doc(postId).delete();

      // Update user's post count
      await _firestore.collection(usersCollection).doc(user.uid).update({
        'postsCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Toggle like on a post
  static Future<bool> toggleLike(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postRef = _firestore.collection(postsCollection).doc(postId);
      final likeRef = postRef.collection(likesCollection).doc(user.uid);

      // First check if the post exists and get current like status
      final postDoc = await postRef.get();
      if (!postDoc.exists) return false;

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike - first update the count using increment
        await postRef.update({'likesCount': FieldValue.increment(-1)});
        // Then delete the like document
        await likeRef.delete();
        return false;
      } else {
        // Like - first create the like document
        await likeRef.set(
            {'userId': user.uid, 'timestamp': FieldValue.serverTimestamp()});
        // Then update the count using increment
        await postRef.update({'likesCount': FieldValue.increment(1)});
        return true;
      }
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Add a comment
  static Future<bool> addComment(String postId, String comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      print('Fetching user data for comment...');
      final userData = await getUserData(user.uid);
      print('User data fetched: $userData');

      // Create the comment with all required fields
      final commentRef = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .collection(commentsCollection)
          .add({
        'text': comment.trim(),
        'userId': user.uid,
        'userName': userData['userName'] ?? 'Anonymous',
        'userAvatar': userData['profileUrl'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (commentRef.id.isNotEmpty) {
        print('Comment created successfully');
        // Update the comment count
        await _firestore
            .collection(postsCollection)
            .doc(postId)
            .update({'commentsCount': FieldValue.increment(1)});
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Delete a comment
  static Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      print('Attempting to delete comment...');
      print('Post ID: $postId');
      print('Comment ID: $commentId');
      print('User ID: ${user.uid}');

      // Get references
      final postRef = _firestore.collection(postsCollection).doc(postId);
      final commentRef = postRef.collection(commentsCollection).doc(commentId);

      // Get comment document first
      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) {
        print('Comment does not exist');
        return false;
      }

      final commentData = commentDoc.data()!;
      print('Comment owner ID: ${commentData['userId']}');

      // If user is comment owner, delete directly
      if (commentData['userId'] == user.uid) {
        print('User is comment owner, proceeding with deletion');
        await commentRef.delete();
        await postRef.update({'commentsCount': FieldValue.increment(-1)});
        print('Comment deleted successfully by comment owner');
        return true;
      }

      // If not comment owner, check if user is post owner
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        print('Post does not exist');
        return false;
      }

      final postData = postDoc.data()!;
      print('Post owner ID: ${postData['userId']}');

      if (postData['userId'] == user.uid) {
        print('User is post owner, proceeding with deletion');
        await commentRef.delete();
        await postRef.update({'commentsCount': FieldValue.increment(-1)});
        print('Comment deleted successfully by post owner');
        return true;
      }

      print('User does not have permission to delete this comment');
      return false;
    } catch (e) {
      print('Error deleting comment: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Mark post as viewed
  static Future<void> markPostAsViewed(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Cannot mark post as viewed: No authenticated user');
        return;
      }

      // First ensure the user profile document exists
      final userProfileRef =
          _firestore.collection(usersCollection).doc(user.uid);

      try {
        // Check if the post is already viewed to avoid unnecessary writes
        final viewedPostRef =
            userProfileRef.collection(viewedPostsCollection).doc(postId);
        final viewedDoc = await viewedPostRef.get();

        if (viewedDoc.exists) {
          print('Post $postId is already marked as viewed');
          return;
        }

        // Create the viewed post document with required fields
        await viewedPostRef.set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'postId': postId,
        });

        print('Successfully marked post $postId as viewed');
      } catch (e) {
        print('Error marking post as viewed: $e');
        if (e is FirebaseException && e.code == 'permission-denied') {
          // Create user profile if it doesn't exist and try again
          await userProfileRef.set({
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'userName': user.displayName ?? 'Anonymous',
            'email': user.email ?? '',
            'profileUrl': user.photoURL ?? '',
          }, SetOptions(merge: true));

          // Try marking as viewed again
          await userProfileRef
              .collection(viewedPostsCollection)
              .doc(postId)
              .set({
            'timestamp': FieldValue.serverTimestamp(),
            'userId': user.uid,
            'postId': postId,
          });
          print(
              'Successfully marked post $postId as viewed after creating profile');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('Error marking post as viewed: $e');
      print('Stack trace: ${StackTrace.current}');
      // Don't rethrow - silently fail for viewed posts as it's not critical
    }
  }

  // Get viewed post IDs with error handling
  static Future<List<String>> getViewedPostIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(viewedPostsCollection)
          .orderBy('timestamp', descending: true)
          .limit(1000)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting viewed posts: $e');
      return [];
    }
  }

  // Clear viewed posts history
  static Future<void> clearViewedPosts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .collection(viewedPostsCollection)
          .limit(500) // Process in batches of 500
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing viewed posts: $e');
    }
  }

  // Get post stream with error handling
  static Stream<QuerySnapshot> getPostsStream({String? tab}) {
    final user = _auth.currentUser;
    if (user == null) {
      return _firestore
          .collection(postsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    if (tab == "Following") {
      return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
        try {
          final userDoc =
              await _firestore.collection(usersCollection).doc(user.uid).get();

          if (!userDoc.exists) {
            return await _firestore
                .collection(postsCollection)
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .get();
          }

          List<String> following =
              List<String>.from(userDoc.data()?['following'] ?? []);
          following.add(user.uid);

          return await _firestore
              .collection(postsCollection)
              .where('userId', whereIn: following)
              .orderBy('createdAt', descending: true)
              .get();
        } catch (e) {
          print('Error getting following posts: $e');
          // Return empty snapshot on error
          return await _firestore
              .collection(postsCollection)
              .where('userId', isEqualTo: user.uid)
              .limit(1)
              .get();
        }
      });
    }

    // For Discover tab, show most liked posts that haven't been viewed
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      try {
        // Get viewed post IDs
        final viewedPosts = await getViewedPostIds();

        // Get posts ordered by likes
        var query = _firestore
            .collection(postsCollection)
            .orderBy('likesCount', descending: true)
            .limit(50);

        // Only apply whereNotIn filter if we have viewed posts
        if (viewedPosts.isNotEmpty) {
          query = query.where(FieldPath.documentId, whereNotIn: viewedPosts);
        }

        return await query.get();
      } catch (e) {
        print('Error getting discover posts: $e');
        // Return empty snapshot on error
        return await _firestore.collection(postsCollection).limit(1).get();
      }
    });
  }

  // Check if post is liked by current user
  static Future<bool> isLikedByUser(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDoc = await _firestore
          .collection(postsCollection)
          .doc(postId)
          .collection(likesCollection)
          .doc(user.uid)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Update post content
  static Future<bool> updatePost(String postId, String newContent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final postDoc =
          await _firestore.collection(postsCollection).doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      if (postData['userId'] != user.uid) return false;

      await _firestore.collection(postsCollection).doc(postId).update({
        'content': newContent.trim(),
        'editedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }
}
