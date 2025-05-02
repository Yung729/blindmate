import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/empty_message.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:blindmate/views/UIComponents/image_frame.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/viewmodels/eventHandlers/redeem_reward_event_handler.dart';

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
  late final RedeemRewardEventHandler rewardEventHandler;

  @override
  void initState() {
    super.initState();
    rewardEventHandler = RedeemRewardEventHandler(user: widget.user!);
    if (widget.user != null) {
      // Assign the current user and fetch rewards
      // _missionEventHandler.handleUserLogin(widget.user!);
      _fetchUserRewards(widget.user!.userId);
    }
  }

  Future<void> _fetchUserRewards(String userId) async {
    uniqueRewards = (await rewardEventHandler
        .handleFetchUserRewards(context, widget.user!.userId))!;
    // List<RewardModel> allFetchedRewards = [];

    // for (var reward in userRewardList) {
    //   if (reward != null) {
    //     allFetchedRewards.add(reward);
    //   }
    // }

    // // Remove duplicates based on redeemRewardId
    // Set<String> seenIds = {};
    // uniqueRewards =
    //     allFetchedRewards.where((reward) {
    //       bool seen = seenIds.contains(reward.redeemRewardId);
    //       if (!seen) seenIds.add(reward.redeemRewardId);
    //       return !seen;
    //     }).toList();

    setState(() {
      _isLoading = false;
    });
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
                                bool isCurrentAvatar =
                                    widget.user?.avatarImg == reward.imageUrl;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: GestureDetector(
                                    onTap:
                                        isCurrentAvatar
                                            ? null
                                            : () async {
                                              final confirm = await showDialog<
                                                bool
                                              >(
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
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(false),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(true),
                                                          child: const Text(
                                                            'Yes',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );

                                              if (confirm == true) {
                                                await rewardEventHandler.switchAvatar(
                                                  widget.user!.userId,
                                                  reward.imageUrl ?? '',
                                                );

                                                // Update global AuthState so all screens react
                                                if (mounted) {
                                                  Provider.of<AuthState>(
                                                    context,
                                                    listen: false,
                                                  ).updateAvatar(
                                                    reward.imageUrl ?? '',
                                                  );
                                                }

                                                setState(() {
                                                  widget.user!.avatarImg =
                                                      reward.imageUrl ?? '';
                                                });
                                              }
                                            },
                                    child: Column(
                                      children: [
                                        NetworkImageBox(
                                          imageUrl: reward.imageUrl,
                                          title: reward.rewardTitle,
                                        ),
                                        CustomButton(
                                          text:
                                              isCurrentAvatar
                                                  ? 'Current'
                                                  : 'Apply',
                                          onPressed:
                                              isCurrentAvatar
                                                  ? null
                                                  : () async {
                                                    final confirm = await showDialog<
                                                      bool
                                                    >(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
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
                                                                child:
                                                                    const Text(
                                                                      'Yes',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.of(
                                                                      context,
                                                                    ).pop(
                                                                      false,
                                                                    ),
                                                                child: const Text(
                                                                  'Cancel',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );

                                                    if (confirm == true) {
                                                      

                                                      if (mounted) {
                                                        Provider.of<AuthState>(
                                                          context,
                                                          listen: false,
                                                        ).updateAvatar(
                                                          reward.imageUrl ?? '',
                                                        );
                                                      }

                                                      setState(() {
                                                        widget.user!.avatarImg =
                                                            reward.imageUrl ??
                                                            '';
                                                      });
                                                    }
                                                  },
                                          horizontalPadding: 12,
                                          verticalPadding: 8,
                                          fontSize: 12,
                                          borderRadius: 20,
                                          width: 80,
                                        ),
                                      ],
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
