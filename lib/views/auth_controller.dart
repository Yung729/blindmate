import 'package:flutter/material.dart';
import '../../viewmodels/state/auth_state.dart';
import '../../viewmodels/dataBinding/auth_data_binding.dart';
import '../views/UIComponents/dialog_utils.dart';

class AuthController {
  final AuthState _state;
  final AuthDataBinding _binding;

  AuthController(this._state, this._binding);

  Future<void> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      _state.setError('Email and password cannot be empty');
      return;
    }

    try {
      _state.setLoading(true);
      final result = await _binding.validateAndLogin(context, email, password);

      if (result['success']) {
        _state.setAuthStatus(
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
      _state.setError(e.toString());
    }
  }
}