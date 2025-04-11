import 'package:flutter/material.dart';
import '../../models/dataModels/post_model.dart'; // Import the merged PostModel
import '../../models/dataModels/user_model.dart';

class SharingState extends ChangeNotifier {
  UserModel? currentUser;
  List<PostModel> posts = []; // Use the merged PostModel
  String? currentMusicUrl;
  bool isLoading = false;

  void setCurrentUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  void setPosts(List<PostModel> newPosts) { // Update the type to PostModel
    posts = newPosts;
    notifyListeners();
  }

  void deletePost(String postId) {
    posts.removeWhere((post) => post.id == postId);
    notifyListeners();
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

  void clear() {
    currentUser = null;
    posts = [];
    currentMusicUrl = null;
    isLoading = false;
    notifyListeners();
  }
}