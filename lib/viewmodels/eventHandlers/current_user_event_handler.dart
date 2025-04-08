import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';
import '../state/current_user_state.dart';
import '../dataBinding/current_user_data_binding.dart';

class CurrentUserEventHandler {
  final CurrentUserState currentUserState;
  final CurrentUserDataBinding dataBinding;

  CurrentUserEventHandler({
    required this.currentUserState,
    required this.dataBinding,
  });

  Future<void> fetchUserData(BuildContext context) async {
    UserModel? user = await dataBinding.fetchUserData();
    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    currentUserState.setCurrentUser(user);
  }

  Future<void> logoutUser(BuildContext context) async {
    if (currentUserState.currentUser == null) return;
    await dataBinding.logoutUser(currentUserState.currentUser!.userId);
    currentUserState.clearCurrentUser();
    Navigator.pushReplacementNamed(context, '/login');
  }
}