import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/services/reward_service.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/user_model.dart';

class RedeemRewardDataBinding {
  final RewardService rewardService = RewardService();
  final UserModel user;

  RedeemRewardDataBinding({required this.user});

  Future<void> redeemReward(
    BuildContext context,
    int rewardCost,
    String rewardId, {
    Function(int updatedFragmentNumber)? onSuccess,
    int quantity = 1,
  }) async {
    try {
      if (user.fragmentNumber >= rewardCost) {
        print("User has enough fragments. Proceeding with redemption of $quantity items...");
        final updatedFragmentNumber = await rewardService.redeemReward(
          user.userId,
          rewardCost,
          rewardId,
          quantity: quantity,
        );
        user.fragmentNumber = updatedFragmentNumber;
        if (onSuccess != null) onSuccess(updatedFragmentNumber);
        print(
          "Reward redeemed successfully! Updated fragment number: $updatedFragmentNumber",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(quantity > 1 
            ? 'Redeemed $quantity flowers successfully!' 
            : 'Reward redeemed successfully!')),
        );
      } else {
        print("Not enough fragments to redeem reward.");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not enough fragments!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error redeeming reward: $e')));
    }
  }

  // Fetch the available rewards from RewardService
  Future<List<RewardModel>> getAvailableRewards() async {
    try {
      final rewards = await rewardService.getAvailableRewards();
      return rewards;
    } catch (e) {
      throw Exception("Failed to fetch available rewards: $e");
    }
  }

  // Fetch user rewards (redeemed rewards)
  Future<List<RewardModel>?> fetchUserRewards(String userId) async {
    try {
      final userReward = await rewardService.fetchUserRewards(userId);
      return userReward;
    } catch (e) {
      throw Exception("Failed to fetch user rewards: $e");
    }
  }

  Future<void> switchAvatar(String userId, String imageUrl) async {
    try {
      // Update the avatar in Firebase
      await rewardService.updateUserAvatar(userId, imageUrl);
      print("Avatar switched successfully!");
    } catch (e) {
      print("Error switching avatar: $e");
      rethrow; // Rethrow so the caller can handle the error
    }
  }

  Future<void> resetAvatar(String userId) async {
  try {
    await rewardService.resetUserAvatar(userId);
    print("Avatar reset successfully!");
  } catch (e) {
    print("Error resetting avatar: $e");
    rethrow;
  }
}
}
