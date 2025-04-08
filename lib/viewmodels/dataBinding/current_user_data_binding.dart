import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/dataModels/user_model.dart';

class CurrentUserDataBinding {
  Future<UserModel?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return null;

    return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
  }

  Future<void> logoutUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'online': false,
      'status': 'available',
      'deviceId': '',
    });
    await FirebaseAuth.instance.signOut();
  }
}