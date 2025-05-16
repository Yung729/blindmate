import 'package:blindmate/viewmodels/dataBinding/redeem_reward_data_binding.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/services/auth_service.dart';

class RedeemRewardEventHandler {
  final UserModel user;
  final RedeemRewardDataBinding dataBinding;

  // Constructor
  RedeemRewardEventHandler({required this.user})
    : dataBinding = RedeemRewardDataBinding(user: user);

  // Handle the redeem reward event
  Future<void> handleRedeemReward(
    BuildContext context,
    int rewardCost,
    String rewardId, {
    Function(int updatedFragmentNumber)? onSuccess,
    int quantity = 1,
  }) async {
    try {
      // Calculate total cost for multiple redemptions
      final totalCost = rewardCost * quantity;
      
      // Call redeemReward method from DataBinding with the total cost
      await dataBinding.redeemReward(
        context,
        totalCost,
        rewardId,
        onSuccess: onSuccess,
        quantity: quantity,
      );
    } catch (e) {
      // Handle any errors that might have occurred
      print("Error in redeeming reward: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Handle fetching available rewards (calling DataBinding method)
  Future<List<RewardModel>> handleFetchAvailableRewards(
    BuildContext context,
    String userId,
  ) async {
    try {
      final rewards = await dataBinding.getAvailableRewards();
      final userReward = await dataBinding.fetchUserRewards(userId);
      final redeemedRewardIds =
          userReward?.map((r) => r.redeemRewardId).toSet() ?? {};
      // Use the rewards list in your UI or pass it to other parts of your app
      print('Available rewards: $rewards');
      final unredeemedRewards =
          rewards.where((reward) {
            if (reward.rewardTitle == 'flower') return true;
            return !redeemedRewardIds.contains(reward.redeemRewardId);
          }).toList();

      print('Filtered unredeemed rewards: ${unredeemedRewards.length}');
      return unredeemedRewards;
    } catch (e) {
      print("Error in fetching rewards: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch rewards: $e')));
      rethrow;
    }
  }

  // Handle fetching user rewards (calling DataBinding method)
  Future<List<RewardModel>?> handleFetchUserRewards(
    BuildContext context,
    String userId,
  ) async {
    try {
      final userReward = await dataBinding.fetchUserRewards(userId);
      // Use the fetched user rewards in your UI
      print('User rewards: $userReward');
      print('User rewards: ${userReward!.length}');
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

  Future<UserModel?> switchAvatar(String userId, String imageUrl) async {
    try {
      // Update avatar in Firebase
      await dataBinding.switchAvatar(userId, imageUrl);

      // Fetch updated user data from Firebase to ensure UI reflects the change
      final authService = AuthService();
      final updatedUser = await authService.loadUserData();

      // Return the updated user data
      return updatedUser;
    } catch (e) {
      print("Error in switching avatar: $e");
      return null;
    }
  }

  Future<void> handleResetAvatar(BuildContext context, AuthState authState) async {
    try {
      await dataBinding.resetAvatar(user.userId);

      // Update AuthState after resetting avatar
      authState.updateAvatar('https://tse3.mm.bing.net/th/id/OIP.XXbgSKiEDzYZDqZQ4hYfvQHaHu?rs=1&pid=ImgDetMain');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Avatar reset to default.")),
      );
    } catch (e) {
      print("Error in handleResetAvatar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reset avatar: $e")),
      );
    }
  }
}
