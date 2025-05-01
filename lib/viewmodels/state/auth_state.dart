import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:flutter/material.dart';

class AuthState with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool isLoggedIn = false;
  String? userId;
  String? userName;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }

  void setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setAuthStatus({
    required bool isLoggedIn,
    String? userId,
    String? userName,
  }) {
    this.isLoggedIn = isLoggedIn;
    this.userId = userId;
    this.userName = userName;
    notifyListeners();
  }

  void clear() {
    isLoading = false;
    errorMessage = null;
    isLoggedIn = false;
    userId = null;
    userName = null;
    notifyListeners();
  }

  void updateAvatar(String newAvatarUrl) {
  if (_currentUser != null) {
    _currentUser!.avatarImg = newAvatarUrl;
    notifyListeners();
  }
}
}
