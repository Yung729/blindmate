import 'package:flutter/material.dart';
import '../../models/dataModels/shared_post_model.dart';
import '../../models/dataModels/user_model.dart';

class SharingState extends ChangeNotifier {
  UserModel? currentUser;
  List<SharedPostModel> posts = [];
  String? currentMusicUrl;
  bool isLoading = false;

  void setCurrentUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }

  void setPosts(List<SharedPostModel> newPosts) {
    posts = newPosts;
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