import 'package:blindmate/views/screens/redeem_reward_screen.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/services/reward_service.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart'; // Assuming you have this model

class RedeemRewardEventHandler {
  final UserModel user;
  final RewardService rewardService;

  RedeemRewardEventHandler({required this.user}) : rewardService = RewardService();

  // Redeem the reward
  Future<void> redeemReward(BuildContext context, int rewardCost, String rewardId,
    {
      Function(int updatedFragmentNumber)? onSuccess,
    }
  ) async {
    try {
      if (user.fragmentNumber >= rewardCost) {
        print("User has enough fragments. Proceeding with redemption...");
        final updatedFragmentNumber = await rewardService.redeemReward(
        user.userId,
        rewardCost,
        rewardId,
      );
      user.fragmentNumber = updatedFragmentNumber;
      if (onSuccess != null) onSuccess(updatedFragmentNumber);
      print("Reward redeemed successfully! Updated fragment number: $updatedFragmentNumber");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward redeemed successfully!')),
        );
      } else {
        print("Not enough fragments to redeem reward.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough fragments!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error redeeming reward: $e')),
      );
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
  Future<UserReward?> fetchUserRewards(String userId) async {
    try {
      final userReward = await rewardService.fetchUserRewards(userId);
      return userReward;
    } catch (e) {
      throw Exception("Failed to fetch user rewards: $e");
    }
  }
}