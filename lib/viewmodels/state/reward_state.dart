import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:flutter/material.dart';

class RewardState with ChangeNotifier {
  // Rewards available for redemption
  List<RewardModel> _availableRewards = [];

  // Rewards already redeemed by the user
  List<RewardModel> _userRewards = [];

  // Getters
  List<RewardModel> get availableRewards => _availableRewards;
  List<RewardModel> get userRewards => _userRewards;

  // Set available rewards (from Firestore)
  void setAvailableRewards(List<RewardModel> rewards) {
    _availableRewards = rewards;
    notifyListeners();
  }

  // Set user's redeemed rewards
  void setUserRewards(List<RewardModel> rewards) {
    _userRewards = rewards;
    notifyListeners();
  }

  // Add a reward to user's redeemed rewards
  void addUserReward(RewardModel reward) {
    if (!_userRewards.any((r) => r.redeemRewardId == reward.redeemRewardId)) {
      _userRewards.add(reward);
      notifyListeners();
    }
  }

  // Remove a reward from available rewards (after redeeming)
  void removeAvailableReward(String rewardId) {
    _availableRewards.removeWhere((r) => r.redeemRewardId == rewardId);
    notifyListeners();
  }

  // Clear all rewards
  void clear() {
    _availableRewards = [];
    _userRewards = [];
    notifyListeners();
  }

  // Clear only available rewards
  void clearAvailableRewards() {
    _availableRewards = [];
    notifyListeners();
  }

  // Clear only user's redeemed rewards
  void clearUserRewards() {
    _userRewards = [];
    notifyListeners();
  }

  bool get isEmpty => _userRewards.isEmpty;
}
