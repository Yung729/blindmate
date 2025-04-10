import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dataModels/shared_post_model.dart';
import '../models/dataModels/user_model.dart';

class SharingService {
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

  // Get shared posts
  Stream<List<SharedPostModel>> getSharedPosts(String? currentUserId) {
    return _firestore
        .collection('shared_content')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SharedPostModel.fromMap(doc.data(), doc.id))
          .where((post) =>
              post.visibility == 'public' || post.userId == currentUserId)
          .toList();
    });
  }

  // Create a new post
  Future<void> createPost(SharedPostModel post) async {
    await _firestore.collection('shared_content').add(post.toMap());
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
}