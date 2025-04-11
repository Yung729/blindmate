import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/dataModels/user_model.dart';
import '../../models/dataModels/mission_model.dart';
import '../../models/dataModels/user_reward_model.dart';

class DoMissionDataBinding {
  UserModel? _currentUser;
  String? userId;

  UserModel? get currentUser => _currentUser;

  Future<List<UserReward>> fetchUserRewards(String userId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('user_reward')
              .where('userId', isEqualTo: userId)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) => UserReward.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching user rewards: $e");
      return [];
    }
  }

  void assignCurrentUserId(UserModel? user) {
    if (user != null) {
      _currentUser = user;
      userId = user.userId; 
      print("Assigned UserId: $userId");
    } else {
      print("No current user found.");
    }
  }
}
