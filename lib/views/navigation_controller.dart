import 'package:blindmate/viewmodels/dataBinding/auth_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/auth_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/views/screens/bottle_note_home_screen.dart';
import 'package:blindmate/views/screens/my_bottle_note_screen.dart';
import 'package:blindmate/views/screens/pick_up_screen.dart';
import 'package:blindmate/views/screens/redeem_reward_screen.dart';
import 'package:blindmate/views/screens/send_bottle_note_screen.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/sharing_screen.dart';
import 'screens/do_mission_screen.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  late AuthEventHandler _userEventHandler;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final currentUserState = context.read<AuthState>();
    final dataBinding = AuthDataBinding();
    _userEventHandler = AuthEventHandler(
      currentUserState,
      dataBinding,
    );
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    await _userEventHandler.fetchUserData(context);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserState = context.watch<AuthState>();

    if (currentUserState.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> screens = [
      const HomeScreen(),
      SharingScreen(user: currentUserState.currentUser!),
      const DoMissionScreen(),
      const BottleNoteHomeScreen(),
      const PickUpScreen(),
      const SendBottleNoteScreen(),
      const MyBottleNotesScreen(),
      const RedeemRewardScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          screens[_currentIndex],
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 80,
              title: _currentIndex == 0
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.black),
                          const SizedBox(width: 8),
                         Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Level ${currentUserState.currentUser!.levelValue}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 150,
                                child: LinearPercentIndicator(
                                  percent: currentUserState.currentUser!.progressionValue,
                                  backgroundColor: Colors.grey[300],
                                  progressColor: Colors.blue,
                                  lineHeight: 6.0,
                                  animation: true,
                                  animationDuration: 1000,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.black),
                  onPressed: () => _userEventHandler.onLogoutPressed(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Sharing'),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: 'Mission',
          ),
        ],
      ),
    );
  }
}