import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/sharing_screen.dart';
import 'screens/do_mission_screen.dart';
import '../viewmodels/state/current_user_state.dart';
import '../viewmodels/eventHandlers/current_user_event_handler.dart';
import '../viewmodels/dataBinding/current_user_data_binding.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  late CurrentUserEventHandler _userEventHandler;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final currentUserState = context.read<CurrentUserState>();
    final dataBinding = CurrentUserDataBinding();
    _userEventHandler = CurrentUserEventHandler(
      currentUserState: currentUserState,
      dataBinding: dataBinding,
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
    final currentUserState = context.watch<CurrentUserState>();

    if (currentUserState.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> screens = [
      const HomeScreen(),
      SharingScreen(user: currentUserState.currentUser!),
      const DoMissionScreen(),
    ];

    final List<String> titles = ["Home", "Sharing", "Mission"];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _userEventHandler.logoutUser(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: screens[_currentIndex],
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
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Mission'),
        ],
      ),
    );
  }
}
