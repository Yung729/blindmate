import 'package:blindmate/viewmodels/dataBinding/redeem_reward_data_binding.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';

class RedeemRewardEventHandler {
  final UserModel user;
  final RedeemRewardDataBinding dataBinding;

  // Constructor
  RedeemRewardEventHandler({required this.user})
      : dataBinding = RedeemRewardDataBinding(user: user);

  // Handle the redeem reward event
  Future<void> handleRedeemReward(BuildContext context, int rewardCost, String rewardId, {
    Function(int updatedFragmentNumber)? onSuccess,
  }) async {
    try {
      // Call redeemReward method from DataBinding
      await dataBinding.redeemReward(
        context,
        rewardCost,
        rewardId,
        onSuccess: onSuccess,
      );
    } catch (e) {
      // Handle any errors that might have occurred
      print("Error in redeeming reward: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Handle fetching available rewards (calling DataBinding method)
  Future<List<RewardModel>> handleFetchAvailableRewards(BuildContext context) async {
    try {
      final rewards = await dataBinding.getAvailableRewards();
      // Use the rewards list in your UI or pass it to other parts of your app
      // print('Available rewards: $rewards');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Rewards fetched successfully!')),
      // );
      return rewards;
    } catch (e) {
      print("Error in fetching rewards: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch rewards: $e')),
      );
      rethrow;
    }
  }

  // Handle fetching user rewards (calling DataBinding method)
  Future<UserReward?> handleFetchUserRewards(BuildContext context, String userId) async {
    try {
      final userReward = await dataBinding.fetchUserRewards(userId);
      // Use the fetched user rewards in your UI
      print('User rewards: $userReward');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('User rewards fetched successfully!')),
      // );
      return userReward;
    } catch (e) {
      print("Error in fetching user rewards: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user rewards: $e')),
      );
      return null;
    }
  }
}
