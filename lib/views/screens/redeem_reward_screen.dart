import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/viewmodels/eventHandlers/redeem_reward_event_handler.dart';
import 'package:blindmate/viewmodels/state/reward_state.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/empty_message.dart';
import 'package:blindmate/views/UIComponents/reward_click.dart';
import 'package:blindmate/views/screens/switch_avatar_screen.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';
import 'package:blindmate/views/UIComponents/crystal_box.dart';
import 'package:provider/provider.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';

class RedeemRewardScreen extends StatefulWidget {
  final UserModel user;

  const RedeemRewardScreen({super.key, required this.user});

  @override
  _RedeemRewardScreenState createState() => _RedeemRewardScreenState();

  // static Future<UserModel?> fetchUserData() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return null;
  //   final doc =
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(user.uid)
  //           .get();
  //   if (!doc.exists) return null;

  //   return UserModel.fromMap(doc.data()!, doc.id);
  // }
}

class _RedeemRewardScreenState extends State<RedeemRewardScreen> {
  UserModel? user;
  // List<RewardModel> _rewards = [];
  bool _isLoading = true;
  late RedeemRewardEventHandler _rewardEventHandler;

  AuthState get _authState => Provider.of<AuthState>(context, listen: false);
  RewardState get _rewardState => Provider.of<RewardState>(context, listen: false);
  UserModel? get _user => _authState.currentUser;

  @override
  void initState() {
    super.initState();
    final user = _authState.currentUser;
    final rewardState = Provider.of<RewardState>(context, listen: false);
    print("AuthState user: ${_user?.userId}");
    if (user != null) {
      _rewardEventHandler = RedeemRewardEventHandler(user: user);
      _initializeScreen();
    }
  }

  Future<void> _initializeScreen() async {
    // setState(() => user = widget.user);
    await _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      setState(() => _isLoading = true);
      // final user = _authState.currentUser;

      final allRewards = await _rewardEventHandler.handleFetchAvailableRewards(
        context,
        _user!.userId,
      );
      final userRewards = await _rewardEventHandler.handleFetchUserRewards(
        context,
        _user!.userId,
      );

      _rewardState.setAvailableRewards(allRewards);
      _rewardState.setUserRewards(userRewards ?? []);

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error initializing rewards: $e");
      setState(() => _isLoading = false);
    }

    // await _loadUserData(); // Ensure current user is loaded
    // await _loadRewards(); // Now you can use user safely
  }

  void _redeemReward(RewardModel reward) async {
    final user = _authState.currentUser;
    final userFragments = user!.fragmentNumber;
    final rewardCost = reward.fragmentCost;

    print("Attempting to redeem reward: ${reward.rewardTitle}");
    print("Current fragments: $userFragments, Reward cost: $rewardCost");

    if (userFragments >= rewardCost) {
      print("User has enough fragments. Proceeding with redemption...");

      try {
        _rewardEventHandler.handleRedeemReward(
          context,
          rewardCost,
          reward.redeemRewardId,
          onSuccess:
              (updatedFragmentNumber) => setState(() {
                user!.fragmentNumber = updatedFragmentNumber;
                if (reward.rewardTitle != 'flower') {
                  // _rewards.removeWhere(
                  //   (r) => r.redeemRewardId == reward.redeemRewardId,
                  // );
                  _rewardState.removeAvailableReward(reward.redeemRewardId);
                  _rewardState.addUserReward(reward);
                }
              }),
        );

        print(
          "Reward redeemed successfully. New fragment number: ${user!.fragmentNumber}",
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
    final user = Provider.of<AuthState>(context).currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Redeem Reward")),
      body:
          user == null || _isLoading
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
                    buildCrystalBox(
                      '${user!.fragmentNumber}',
                    ), // Optional: using your shared method
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Align(
                          alignment:
                              Alignment.topLeft, // ✅ Force left alignment
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start, // ✅ Ensure children are left-aligned
                            children: [
                              RewardSection(
                                rewards: _rewardState.availableRewards,
                                onRewardTap: _redeemReward,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    CustomButton(
                      text: "My Avatar",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    SwitchAvatarScreen(user: user!),
                          ),
                          // ).then((_) {
                          //   _loadUserData();
                          // });
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}

class RewardSection extends StatelessWidget {
  final List<RewardModel> rewards;
  final Function(RewardModel) onRewardTap;

  const RewardSection({
    super.key,
    required this.rewards,
    required this.onRewardTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRewards =
        rewards.where((r) => r.rewardTitle != 'flower').toList();
    final flowerRewards =
        rewards.where((r) => r.rewardTitle == 'flower').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Avatar",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        avatarRewards.isEmpty
            ? EmptyRewardsMessage(
              message: "All avatar rewards have been redeemed!",
            )
            : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children:
                    avatarRewards
                        .map(
                          (reward) => Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: RewardButton(
                              imagePath: reward.imageUrl,
                              title: reward.rewardTitle,
                              cost: reward.fragmentCost,
                              onPressed: () async {
                                final confirm = await _confirmRedemption(
                                  context,
                                  reward,
                                );
                                if (confirm) onRewardTap(reward);
                              },
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
        const SizedBox(height: 24),
        const Text(
          "Flower",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children:
                flowerRewards
                    .map(
                      (reward) => Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: RewardButton(
                          imagePath: reward.imageUrl,
                          title: reward.rewardTitle,
                          cost: reward.fragmentCost,
                          onPressed: () async {
                            final confirm = await _confirmRedemption(
                              context,
                              reward,
                            );
                            if (confirm) onRewardTap(reward);
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmRedemption(
    BuildContext context,
    RewardModel reward,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Redemption'),
                content: Text(
                  'Redeem "${reward.rewardTitle}" for ${reward.fragmentCost} crystals?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }
}
