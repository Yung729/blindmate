
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dataModels/post_model.dart';
import '../models/dataModels/user_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user data
  Future<UserModel?> loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id,
        );
      }
    }
    return null;
  }

  // Get shared posts (now just "posts")
  Stream<List<PostModel>> getPosts(String? currentUserId) {
    return _firestore
        .collection('shared_content')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((post) =>
              post.visibility == 'public' || post.userId == currentUserId)
          .toList();
    });
  }

  // Create a new post
  Future<void> createPost(PostModel post) async {
    await _firestore.collection('shared_content').add(post.toMap());
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('shared_content').doc(postId).delete();
    } catch (e) {
      print("Error deleting post from Firestore: $e");
      throw e; // Re-throw the error to be caught in the EventHandler
    }
  }

  // Update post visibility (and potentially other fields)
  Future<void> updatePost(String postId, Map<String, dynamic> updateData) async {
    try {
      await _firestore.collection('shared_content').doc(postId).update(updateData);
    } catch (e) {
      print("Error updating post in Firestore: $e");
      throw e; // Re-throw the error
    }
  }

  // Helper method for extracting YouTube video IDs
  String? extractYouTubeVideoId(String url) {
    RegExp regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?/ ]{11})',
      caseSensitive: false,
      multiLine: false,
    );
    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Extract URLs from content
  String? extractUrlFromContent(String content) {
    RegExp urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    Match? urlMatch = urlRegExp.firstMatch(content);
    return urlMatch?.group(0);
  }

  // =========================
  // Hidden Posts Management
  // =========================

  /// Fetch hidden post IDs for the current user
  Future<List<String>> getHiddenPosts() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['hiddenPosts'] != null) {
      return List<String>.from(data['hiddenPosts']);
    }
    return [];
  }

  /// Hide a post for the current user (add postId to hiddenPosts)
  Future<void> hidePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'hiddenPosts': FieldValue.arrayUnion([postId])
    }, SetOptions(merge: true));
  }

  /// Unhide a post for the current user (remove postId from hiddenPosts)
  Future<void> unhidePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'hiddenPosts': FieldValue.arrayRemove([postId])
    }, SetOptions(merge: true));
  }
}
