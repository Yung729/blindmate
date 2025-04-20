import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/viewmodels/dataBinding/do_mission_data_binding.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:blindmate/views/UIComponents/image_frame.dart';
import 'package:flutter/material.dart';

class SwitchAvatarScreen extends StatefulWidget {
  final UserModel? user;
  const SwitchAvatarScreen({super.key, required this.user});

  @override
  _SwitchAvatarScreenState createState() => _SwitchAvatarScreenState();
}

class _SwitchAvatarScreenState extends State<SwitchAvatarScreen> {
  List<UserReward> redeemRewardId = [];
  List<RewardModel> uniqueRewards = [];

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // Assign the current user and fetch rewards
      DoMissionDataBinding().assignCurrentUserId(widget.user);
      _fetchUserRewards(widget.user!.userId);
    }
  }

  Future<void> _fetchUserRewards(String userId) async {
  List<UserReward> userRewardList = await DoMissionDataBinding().fetchUserRewards(userId);
  List<RewardModel> allFetchedRewards = [];

  for (var userReward in userRewardList) {
    for (var rewardId in userReward.redeemedRewards) {
      RewardModel? reward = await _fetchRewardModelById(rewardId);
      if (reward != null) {
        allFetchedRewards.add(reward);
      }
    }
  }

  // Remove duplicates based on redeemRewardId
  Set<String> seenIds = {};
  uniqueRewards = allFetchedRewards.where((reward) {
    bool seen = seenIds.contains(reward.redeemRewardId);
    if (!seen) seenIds.add(reward.redeemRewardId);
    return !seen;
  }).toList();

  setState(() {
    redeemRewardId = userRewardList;
  });
}


  Future<RewardModel?> _fetchRewardModelById(String rewardId) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('reward')
        .doc(rewardId)
        .get();

    if (docSnapshot.exists) {
      return RewardModel.fromFirestore(docSnapshot);
    }
  } catch (e) {
    print("Error fetching reward: $e");
  }
  return null;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Avatar'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Redeemed Rewards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Display the rewards once they are fetched
            Expanded(
              child: uniqueRewards.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: uniqueRewards.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final reward = uniqueRewards[index];
                        return GestureDetector(
                          onTap: () {
                            // Handle Reward tap (e.g., show details or select)
                            print('Reward ${reward.rewardTitle} tapped');
                          },
                          child: NetworkImageBox(
                            imageUrl: reward.imageUrl, // Assuming RewardModel has imageUrl
                            title: reward.rewardTitle,  // Updated to use rewardTitle
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


