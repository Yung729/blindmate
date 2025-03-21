import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../views/UIComponents/dialog_utils.dart'; // Import error dialog utility
import '../models/dataModels/user_model.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<String> getDeviceId(BuildContext context) async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Theme.of(context).platform == TargetPlatform.android) {
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  } else if (Theme.of(context).platform == TargetPlatform.iOS) {
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? 'unknown';
  }
  return 'unknown';
}

Future<void> loginUser(
  BuildContext context,
  String email,
  String password,
) async {
  if (email.isEmpty || password.isEmpty) return;

  try {
    String deviceId = await getDeviceId(context);

    QuerySnapshot userQuery =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (userQuery.docs.isNotEmpty) {
      var userDoc = userQuery.docs.first;
      bool isOnline = userDoc['online'] ?? false;
      String? storedDeviceId = userDoc['deviceId'];

      if (isOnline && storedDeviceId != null && storedDeviceId != deviceId) {
        showErrorDialog(
          context,
          "You are already logged in on another device.",
        );
        return;
      }
    }

    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = userCredential.user;

    if (user != null) {
      String userId = user.uid;
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();

      String userName = userDoc.exists ? (userDoc['name'] ?? "User") : email;

      await userRef.update({
        'online': true,
        'deviceId': deviceId,
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Store user info locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserId', userId);
      await prefs.setString('currentUserName', userName);

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home'); // Use named route
      }
    }
  } on FirebaseAuthException catch (e) {
    showErrorDialog(context, e.message ?? "Login failed");
  }
}

Future<void> logoutUser(BuildContext context, String userId) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'online': false,
      'status': 'available',
      'deviceId': '',
    });
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: ${e.toString()}")));
    }
  }
}

Future<UserModel?> loadUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (!userDoc.exists) return null;

  return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
}
