import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../pages/home_screen.dart';
import '../pages/sharing_screen.dart';
import '../utils/auth_utils.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  int _currentIndex = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    UserModel? user = await loadUserData();
    if (user == null) {
      Future.microtask(() => 
        Navigator.pushReplacementNamed(context, '/login')
      ); // ✅ Fix navigation issue
      return;
    }

    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> _screens = [
      const HomeScreen(),
      SharingScreen(user: _currentUser!),
    ];

    final List<String> _titles = ["Home", "Sharing"]; // ✅ Dynamic screen titles

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]), // ✅ Change title based on screen
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app), // 🚪 Exit door icon
            onPressed: () => logoutUser(context, _currentUser!.userId),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _screens[_currentIndex],
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
        ],
      ),
    );
  }
}
