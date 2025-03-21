import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';
import 'waiting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();

  static Future<UserModel?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!userDoc.exists) return null;

    return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
  }
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await HomeScreen.fetchUserData();
    setState(() {
      _currentUser = user;
    });
  }

  // 🔹 Show Pop-up with Matching Options
  void _showMatchingOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Choose Matching Type"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startRandomMatching();
                  },
                  child: const Text("Random Matching"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    _startBottleMatching();
                  },
                  child: const Text("Bottle Matching"),
                ),
              ],
            ),
          ),
    );
  }

  // 🔹 Start Random Matching
  void _startRandomMatching() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingScreen(user: _currentUser!),
        ),
      );
    }
  }

  // 🔹 Start Bottle Matching
  void _startBottleMatching() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentUser != null)
              Text(
                "Welcome, ${_currentUser!.name}!",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showMatchingOptions, 
              child: const Text("Start Matching"),
            ),
          ],
        ),
      ),
    );
  }
}
