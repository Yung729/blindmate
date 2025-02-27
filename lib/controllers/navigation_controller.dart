import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../pages/home_screen.dart';
import '../pages/sharing_screen.dart';
import '../pages/login_screen.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  // ✅ Keep Named Routes
  static final Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/home': (context) => const NavigationController(), // Redirects to the main navigation
  };

  static void navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  static void replaceWith(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  int _currentIndex = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      NavigationController.replaceWith(context, '/login'); // ✅ Redirect if not logged in
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;

    setState(() {
      _currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
    });
  }

  void _logout() async {
    await FirebaseFirestore.instance.collection('users').doc(_currentUser!.userId).update({
      'online': false,
      'status': 'available',
    });
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      NavigationController.replaceWith(context, '/login'); // ✅ Logout redirects to Login
    }
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
            onPressed: _logout,
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
