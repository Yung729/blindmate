import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dataModels/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Device ID handling
  Future<String> getDeviceId(BuildContext context) async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    }
    return 'unknown';
  }

  // Session checking
  Future<bool> checkDeviceSession(String email, String deviceId) async {
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      var userDoc = userQuery.docs.first;
      bool isOnline = userDoc['online'] ?? false;
      String? storedDeviceId = userDoc['deviceId'];
      return isOnline && storedDeviceId != null && storedDeviceId != deviceId;
    }
    return false;
  }

  // Authentication
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // User status management
  Future<void> updateUserStatus(String userId, String deviceId, {bool isOnline = true}) async {
    await _firestore.collection('users').doc(userId).update({
      'online': isOnline,
      'deviceId': isOnline ? deviceId : '',
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // Local storage
  Future<void> saveUserLocally(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', userId);
    await prefs.setString('currentUserName', userName);
  }

  // Sign out
  Future<void> signOut(String userId) async {
    await updateUserStatus(userId, '', isOnline: false);
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // User data loading
  Future<UserModel?> loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) return null;

      return UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>, 
        user.uid
      );
    } catch (e) {
      return null;
    }
  }
}