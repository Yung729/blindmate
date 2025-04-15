import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the available rewards from the Firestore collection
  Future<List<RewardModel>> getAvailableRewards() async {
    try {
      final rewardsSnapshot = await _firestore.collection('reward').get();
      return rewardsSnapshot.docs
          .map((doc) => RewardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch rewards: $e");
    }
  }

  // Fetch user rewards (redeemed rewards)
  Future<UserReward?> fetchUserRewards(String userId) async {
    try {
      final userRewardDoc =
          await _firestore.collection('user_reward').doc(userId).get();
      if (userRewardDoc.exists) {
        print('Fetched user reward doc: ${userRewardDoc.data()}');
        return UserReward.fromFirestore(userRewardDoc);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to fetch user rewards: $e");
    }
  }

  // Redeem the reward
  Future<int> redeemReward(
    String userId,
    int fragmentCost,
    String rewardId,
  ) async {
    try {
      // 🔻 Step 1: Update the user's fragmentNumber in Firestore (atomic)
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'fragmentNumber': FieldValue.increment(-fragmentCost),
      });

      // 🔻 Step 2: Fetch updated user data (so all screens get the same number)
      final updatedUserDoc = await userRef.get();
      final updatedFragmentNumber =
          updatedUserDoc.data()?['fragmentNumber'] ?? 0;

      // Fetch the current redeemed rewards
      final userReward = await fetchUserRewards(userId);
      List<dynamic> redeemedRewards = userReward?.redeemedRewards ?? [];

      redeemedRewards.add(rewardId);

      // Update the user_rewards collection with the new list of redeemed rewards
      await _firestore.collection('user_reward').doc(userId).set({
        'userId': userId,
        'redeemedReward': redeemedRewards,
      }, SetOptions(merge: true));
      return updatedFragmentNumber;
    } catch (e) {
      throw Exception("Failed to redeem reward: $e");
    }
  }
}
