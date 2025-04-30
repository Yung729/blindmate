import 'package:blindmate/views/UIComponents/avatar_frame.dart';
import 'package:blindmate/views/UIComponents/empty_message.dart';
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
  bool _isLoading = true;

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
    List<UserReward> userRewardList = await DoMissionDataBinding()
        .fetchUserRewards(userId);
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
    uniqueRewards =
        allFetchedRewards.where((reward) {
          bool seen = seenIds.contains(reward.redeemRewardId);
          if (!seen) seenIds.add(reward.redeemRewardId);
          return !seen;
        }).toList();

    setState(() {
      redeemRewardId = userRewardList;
      _isLoading = false;
    });
  }

  Future<RewardModel?> _fetchRewardModelById(String rewardId) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
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
              'Avatar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(),
                      ) // ✅ Show loader
                      : uniqueRewards.isEmpty
                      ? EmptyRewardsMessage(
                        message: "You have not redeemed any rewards!",
                      )
                      : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              uniqueRewards.map((reward) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Switch Avatar',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to use this avatar?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                  child: const Text('Yes'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(false),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );

                                      if (confirm == true) {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.user!.userId)
                                            .update({
                                              'avatarImg': reward.imageUrl,
                                            });

                                        setState(() {
                                          widget.user!.avatarImg =
                                              reward.imageUrl ?? '';
                                        });
                                      }
                                    },
                                    child: NetworkImageBox(
                                      imageUrl: reward.imageUrl,
                                      title: reward.rewardTitle,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
