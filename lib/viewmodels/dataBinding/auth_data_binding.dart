import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/dataModels/user_model.dart';

class AuthDataBinding {
  final AuthService _service;

  AuthDataBinding(this._service);

  Future<Map<String, dynamic>> validateAndLogin(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final deviceId = await _service.getDeviceId(context);
      final hasExistingSession = await _service.checkDeviceSession(email, deviceId);
      
      if (hasExistingSession) {
        return {
          'success': false,
          'error': 'Already logged in on another device'
        };
      }

      final userCred = await _service.signIn(email, password);
      if (userCred.user != null) {
        await _service.updateUserStatus(userCred.user!.uid, deviceId);
        await _service.saveUserLocally(
          userCred.user!.uid,
          email,
        );
        return {
          'success': true, 
          'userId': userCred.user!.uid,
          'userName': email
        };
      }
      
      return {
        'success': false,
        'error': 'Login failed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  Future<void> handleLogout(String userId) async {
    await _service.signOut(userId);
  }

  Future<UserModel?> getUserData() => _service.loadUserData();
}