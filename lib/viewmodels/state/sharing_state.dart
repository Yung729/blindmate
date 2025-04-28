
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dataModels/post_model.dart';
import '../../models/dataModels/user_model.dart';

class SharingState extends ChangeNotifier {
  UserModel? currentUser;
  List<PostModel> posts = [];
  String? currentMusicUrl;
  bool isLoading = false;
  Set<String> _hiddenPostIds = {};

  SharingState({this.currentUser}) {
    _loadHiddenPosts();
  }

  Set<String> get hiddenPostIds => _hiddenPostIds;

  Future<void> setCurrentUser(UserModel user) async {
  currentUser = user;
  await _loadHiddenPosts();
  notifyListeners();
}

  /// Set hidden post IDs directly (useful for initialization)
  void setHiddenPostIds(Set<String> ids) {
    _hiddenPostIds = ids;
    notifyListeners();
  }

  /// Public method to refresh hidden posts from Firestore
  Future<void> refreshHiddenPosts() async {
    await _loadHiddenPosts();
  }

  Future<void> _loadHiddenPosts() async {
    if (currentUser?.userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.userId)
            .get();
        if (userDoc.exists && userDoc.data()?['hiddenPosts'] != null) {
          _hiddenPostIds = Set<String>.from(userDoc.data()!['hiddenPosts']);
        } else {
          _hiddenPostIds = {};
        }
      } catch (e) {
        print("Error loading hidden posts: $e");
        _hiddenPostIds = {};
      }
    } else {
      _hiddenPostIds = {};
    }
    notifyListeners();
  }

  void setPosts(List<PostModel> newPosts) {
    posts = newPosts;
    notifyListeners();
  }

  void deletePost(String postId) {
    // Find the post and update its visibility to 'deleted'
    final index = posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      posts[index].visibility = 'deleted';
      notifyListeners();
    }
  }

  void toggleVisibility(String postId) {
    final post = posts.firstWhere((post) => post.id == postId);
    post.isPublic = !post.isPublic;
    notifyListeners();
  }

  void setCurrentMusicUrl(String? url) {
    currentMusicUrl = url;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  Future<void> hidePost(String postId) async {
    if (currentUser?.userId != null) {
      _hiddenPostIds.add(postId);
      notifyListeners();
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.userId)
            .update({
          'hiddenPosts': FieldValue.arrayUnion([postId]),
        });
        print("Post $postId hidden in Firebase");
      } catch (e) {
        print("Error hiding post in Firebase: $e");
        _hiddenPostIds.remove(postId);
        notifyListeners();
      }
    }
  }

  Future<void> unhidePost(String postId) async {
    if (currentUser?.userId != null) {
      _hiddenPostIds.remove(postId);
      notifyListeners();
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.userId)
            .update({
          'hiddenPosts': FieldValue.arrayRemove([postId]),
        });
        print("Post $postId unhidden in Firebase");
      } catch (e) {
        print("Error unhiding post in Firebase: $e");
        _hiddenPostIds.add(postId);
        notifyListeners();
      }
    }
  }

  void clear() {
    currentUser = null;
    posts = [];
    currentMusicUrl = null;
    isLoading = false;
    _hiddenPostIds.clear();
    notifyListeners();
  }
}
