import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../dataBinding/auth_data_binding.dart';
import '../../views/UIComponents/custom_dialog.dart';

class AuthEventHandler {
  final AuthState _authState;
  final AuthDataBinding _dataBinding;

  AuthEventHandler(this._authState, this._dataBinding);

  Future<void> onLoginPressed(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _authState.setError('Email and password cannot be empty');
      return;
    }

    try {
      _authState.setLoading(true);
      final result = await _dataBinding.validateAndLogin(
        context,
        email,
        password,
      );

      if (result['success']) {
        _authState.setAuthStatus(
          isLoggedIn: true,
          userId: result['userId'],
          userName: email,
        );
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (context.mounted) {
          showErrorDialog(context, result['error']);
        }
      }
    } catch (e) {
      _authState.setError(e.toString());
    } finally {
      _authState.setLoading(false);
    }
  }

  Future<void> onLogoutPressed(BuildContext context) async {
    try {
      _authState.setLoading(true);
      final userId = _authState.currentUser?.userId;
      if (userId != null) {
        // Ensure user is marked offline before logging out
        await _dataBinding.updateUserStatus(userId, '', isOnline: false);
        await _dataBinding.signOut(userId);
      }
      _authState.clear();
      _authState.clearCurrentUser();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      _authState.setError('Failed to logout');
    } finally {
      _authState.setLoading(false);
    }
  }

  Future<UserModel?> fetchUserData(BuildContext context) async {
    try {
      UserModel? user = await _dataBinding.getUserData();
      if (user != null) {
        _authState.setCurrentUser(user);
      }
      return user;
    } catch (e) {
      _authState.setError(e.toString());
      return null;
    }
  }

  Future<void> onEmotionSelected(BuildContext context, String emotion) async {
    final userId = _authState.currentUser?.userId;
    if (userId == null) return;
    await _dataBinding.updateEmotionalStatus(userId, emotion);
    // Refresh user data so UI updates
    await fetchUserData(context);
  }
}
