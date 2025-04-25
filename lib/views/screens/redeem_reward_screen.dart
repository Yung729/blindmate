import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/services/reward_service.dart';
import 'package:blindmate/viewmodels/eventHandlers/redeem_reward_event_handler.dart';
import 'package:blindmate/views/UIComponents/avatar_frame.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/reward_click.dart';
import 'package:blindmate/views/screens/switch_avatar_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';
import 'package:blindmate/views/UIComponents/crystal_box.dart';

class RedeemRewardScreen extends StatefulWidget {
  final UserModel user;

  const RedeemRewardScreen({super.key, required this.user});

  @override
  _RedeemRewardScreenState createState() => _RedeemRewardScreenState();

  static Future<UserModel?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }
}

class _RedeemRewardScreenState extends State<RedeemRewardScreen> {
  UserModel? _currentUser;
  List<RewardModel> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRewards();
  }

  Future<void> _loadUserData() async {
    final user = await RedeemRewardScreen.fetchUserData();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadRewards() async {
    try {
      final rewards = await RewardService().getAvailableRewards();
      print("Fetched rewards: ${rewards.map((e) => e.rewardTitle).toList()}");
      setState(() {
        _rewards = rewards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching rewards: $e')));
    }
  }

  // void _redeemReward(RewardModel reward) async {
  //   final userFragments = _currentUser!.fragmentNumber;
  //   final rewardCost = reward.fragmentCost;

  //   print("Attempting to redeem reward: ${reward.rewardTitle}");
  //   print("Current fragments: $userFragments, Reward cost: $rewardCost");
  //   //   if (_currentUser!.fragmentNumber >= reward.fragmentCost) {
  //   //     setState(() {
  //   //       _currentUser!.fragmentNumber -= reward.fragmentCost;
  //   //     });

  //   //     // Call reward redemption logic (you can update Firestore here if needed)
  //   //     final handler = RedeemRewardEventHandler(user: _currentUser!);
  //   //     handler.redeemReward(context, reward.fragmentCost, reward.redeemRewardId);
  //   //   }
  //   // }
  //   if (userFragments is num &&
  //       rewardCost is num &&
  //       userFragments >= rewardCost) {
  //     print("User has enough fragments. Proceeding with redemption...");
  //     setState(() {
  //       _currentUser!.fragmentNumber -= reward.fragmentCost;
  //     });
  //     print(
  //       "Fragments deducted. New fragment number: ${_currentUser!.fragmentNumber}",
  //     );

  //     try {
  //       // print("Updating Firestore with new fragment number...");
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(_currentUser!.userId)
  //           .update({'fragmentNumber': _currentUser!.fragmentNumber});
  //       // print("Firestore update successful.");

  //       final handler = RedeemRewardEventHandler(user: _currentUser!);
  //       handler.redeemReward(
  //         context,
  //         reward.fragmentCost,
  //         reward.redeemRewardId,
  //         onSuccess:
  //             (updatedFragmentNumber) => setState(() {
  //               _currentUser?.fragmentNumber = updatedFragmentNumber;
  //             }),
  //       );

  //       // print("Reward redemption processed successfully.");
  //     } catch (e) {
  //       // print("Error during Firestore update: $e");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Error updating Firestore. Please try again later.'),
  //         ),
  //       );
  //     }
  //   } else {
  //     // print("Not enough crystals. User fragments: $userFragments, Required: $rewardCost");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Not enough crystals to redeem this reward.'),
  //       ),
  //     );
  //   }
  // }
  void _redeemReward(RewardModel reward) async {
    final userFragments = _currentUser!.fragmentNumber;
    final rewardCost = reward.fragmentCost;

    print("Attempting to redeem reward: ${reward.rewardTitle}");
    print("Current fragments: $userFragments, Reward cost: $rewardCost");

    if (userFragments >= rewardCost) {
      print("User has enough fragments. Proceeding with redemption...");

      try {
        // Deduct fragments locally first (before Firestore update)
        final newFragmentNumber = userFragments - rewardCost;

        // Call the redeem reward method
        final handler = RedeemRewardEventHandler(user: _currentUser!);
        handler.redeemReward(
          context,
          rewardCost,
          reward.redeemRewardId,
          onSuccess:
              (updatedFragmentNumber) => setState(() {
                _currentUser!.fragmentNumber = updatedFragmentNumber;
              }),
        );

        print(
          "Reward redeemed successfully. New fragment number: ${_currentUser!.fragmentNumber}",
        );
      } catch (e) {
        print("Error during reward redemption: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating Firestore. Please try again later.'),
          ),
        );
      }
    } else {
      print("Not enough crystals to redeem this reward.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough crystals to redeem this reward.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Redeem Reward")),
      body:
          _currentUser == null || _isLoading
              ? Center(child: CircularProgressIndicator())
              : Container(
                padding: const EdgeInsets.only(
                  top: 40.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: Column(
                  // ✅ Use Column here instead of children on Container
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AvatarFrame(
                          imagePath: _currentUser!.avatarImg,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        SwitchAvatarScreen(user: _currentUser!),
                              ),
                            ).then((_) {
                              _loadUserData();
                            });
                          },
                        ),
                      ],
                    ),
                    buildCrystalBox(
                      '${_currentUser!.fragmentNumber}',
                    ), // Optional: using your shared method
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        "Redeem Rewards",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RewardGrid(
                        rewards: _rewards,
                        onRewardTap: (reward) {
                          _redeemReward(reward);
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class RewardGrid extends StatelessWidget {
  final List<RewardModel> rewards;
  final Function(RewardModel) onRewardTap;

  const RewardGrid({
    super.key,
    required this.rewards,
    required this.onRewardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rewards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return RewardButton(
          imagePath: reward.imageUrl ?? '',
          title: reward.rewardTitle ?? 'Reward',
          cost: reward.fragmentCost ?? 0,
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Confirm Redemption'),
                    content: Text(
                      'Are you sure you want to redeem "${reward.rewardTitle}" for ${reward.fragmentCost} crystals?',
                    ),
                    actions: [
<<<<<<< Updated upstream
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
=======
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
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
>>>>>>> Stashed changes
                  ),
            );

            if (confirm == true) {
              onRewardTap(reward);
            }
          },
        );
      },
    );
  }
}
