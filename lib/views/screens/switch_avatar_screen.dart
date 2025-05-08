import 'package:blindmate/viewmodels/state/reward_state.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/empty_message.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
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
  // List<RewardModel> uniqueRewards = [];
  bool _isLoading = true;
  late final RedeemRewardEventHandler rewardEventHandler;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthState>(context, listen: false).currentUser;
    print("AuthState user: ${user?.userId}");
    if (user != null) {
      rewardEventHandler = RedeemRewardEventHandler(user: user);
      _fetchUserRewards(user.userId);
    }
    // rewardEventHandler = RedeemRewardEventHandler(user: widget.user!);
    // if (widget.user != null) {
    //   // Assign the current user and fetch rewards
    //   // _missionEventHandler.handleUserLogin(widget.user!);
    //   _fetchUserRewards(widget.user!.userId);
    // }
  }

  Future<void> _fetchUserRewards(String userId) async {
    await rewardEventHandler.handleFetchUserRewards(context, userId);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rewardState = context.watch<RewardState>();
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
            const SizedBox(height: 10),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(),
                      ) // ✅ Show loader
                      : rewardState.isEmpty
                      ? EmptyRewardsMessage(
                        message: "You have not redeemed any rewards!",
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: rewardState.userRewards.length,
                        itemBuilder: (context, index) {
                          final reward = rewardState.userRewards[index];
                          bool isCurrentAvatar =
                              widget.user?.avatarImg == reward.imageUrl;

                          return GestureDetector(
                            onTap:
                                isCurrentAvatar
                                    ? null
                                    : () async {
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
                                                      ).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
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
                                        // Get updated user including refreshed avatar
                                        final updatedUser =
                                            await rewardEventHandler
                                                .switchAvatar(
                                                  widget.user!.userId,
                                                  reward.imageUrl,
                                                );

                                        // Update global AuthState so all screens react
                                        if (mounted && updatedUser != null) {
                                          final authState =
                                              Provider.of<AuthState>(
                                                context,
                                                listen: false,
                                              );
                                          // Update the entire user object, not just the avatar
                                          authState.setCurrentUser(updatedUser);

                                          // Update local state
                                          setState(() {
                                            // Use the updated user data from Firebase
                                            widget.user!.avatarImg =
                                                updatedUser.avatarImg;
                                          });
                                        }
                                      }
                                    },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                NetworkImageBox(
                                  imageUrl: reward.imageUrl,
                                  title: reward.rewardTitle,
                                ),
                                CustomButton(
                                  text: isCurrentAvatar ? 'Current' : 'Apply',
                                  onPressed:
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
                                                            () => Navigator.of(
                                                              context,
                                                            ).pop(false),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.of(
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
                                              final updatedUser =
                                                  await rewardEventHandler
                                                      .switchAvatar(
                                                        widget.user!.userId,
                                                        reward.imageUrl,
                                                      );

                                              if (mounted &&
                                                  updatedUser != null) {
                                                final authState =
                                                    Provider.of<AuthState>(
                                                      context,
                                                      listen: false,
                                                    );
                                                authState.setCurrentUser(
                                                  updatedUser,
                                                );

                                                setState(() {
                                                  widget.user!.avatarImg =
                                                      updatedUser.avatarImg;
                                                });
                                              }
                                            }
                                          },
                                  horizontalPadding: 12,
                                  verticalPadding: 8,
                                  fontSize: 12,
                                  borderRadius: 20,
                                  width: 80,
                                  backgroundColor:
                                      isCurrentAvatar
                                          ? Colors.green
                                          : Colors.blue,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            Center(
              child: CustomButton(
                text: "Reset Avatar",
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Reset Avatar'),
                          content: const Text(
                            'Are you sure you want to reset your avatar to the default one?',
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
                  );

                  if (confirm == true) {
                    final authState = Provider.of<AuthState>(
                      context,
                      listen: false,
                    );
                    await rewardEventHandler.handleResetAvatar(
                      context,
                      authState,
                    );

                    if (mounted) {
                      setState(() {
                        widget.user!.avatarImg =
                            'https://tse3.mm.bing.net/th/id/OIP.XXbgSKiEDzYZDqZQ4hYfvQHaHu?rs=1&pid=ImgDetMain';
                      });
                    }
                  }
                },

                // onPressed: () async {
                //   final authState = Provider.of<AuthState>(
                //     context,
                //     listen: false,
                //   );
                //   await rewardEventHandler.handleResetAvatar(
                //     context,
                //     authState,
                //   );

                //   if (mounted) {
                //     setState(() {
                //       widget.user!.avatarImg =
                //           'https://tse3.mm.bing.net/th/id/OIP.XXbgSKiEDzYZDqZQ4hYfvQHaHu?rs=1&pid=ImgDetMain';
                //     });
                //   }
                // },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
