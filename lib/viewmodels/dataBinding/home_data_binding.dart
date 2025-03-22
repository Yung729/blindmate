import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dataModels/user_model.dart';

class HomeDataBinding {
  Future<UserModel?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return null;

    return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
  }
}