import 'package:blindmate/models/dataModels/redeem_rewards_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch the available rewards from the Firestore collection
  Future<List<RewardModel>> getAvailableRewards() async {
    try {
      final rewardsSnapshot = await _firestore.collection('rewards').get();
      return rewardsSnapshot.docs
          .map((doc) => RewardModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch rewards: $e");
    }
  }

  // Fetch user rewards (redeemed rewards)
  Future<UserReward?> fetchUserRewards(String userId) async {
    try {
      final userRewardDoc = await _firestore.collection('user_rewards').doc(userId).get();
      if (userRewardDoc.exists) {
        return UserReward.fromFirestore(userRewardDoc);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to fetch user rewards: $e");
    }
  }

  // Redeem the reward
  Future<void> redeemReward(String userId, int fragmentCost, String rewardId) async {
    try {
      // Assume user has enough fragments (you can add additional checks here)
      await _firestore.collection('users').doc(userId).update({
        'fragmentNumber': FieldValue.increment(-fragmentCost), // Deduct fragments
      });

      // Fetch the current redeemed rewards
      final userReward = await fetchUserRewards(userId);
      List<dynamic> redeemedRewards = userReward?.redeemedRewards ?? [];

      // Add the new reward to the list of redeemed rewards
      redeemedRewards.add(rewardId);

      // Update the user_rewards collection with the new list of redeemed rewards
      await _firestore.collection('user_rewards').doc(userId).set({
        'userId': userId,
        'redeemedReward': redeemedRewards,
      }, SetOptions(merge: true));

    } catch (e) {
      throw Exception("Failed to redeem reward: $e");
    }
  }
}
