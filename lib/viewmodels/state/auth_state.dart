import 'package:flutter/material.dart';

class AuthState with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool isLoggedIn = false;
  String? userId;
  String? userName;

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
}