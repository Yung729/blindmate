import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';

class HomeState with ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }
}