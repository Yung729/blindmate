import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';
import 'package:blindmate/views/UIComponents/crystal_box.dart';

class RedeemRewardScreen extends StatefulWidget {
  const RedeemRewardScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await RedeemRewardScreen.fetchUserData();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Redeem Reward")),
      body: Container(
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
              '${_currentUser!.fragmentNumber}',
            ), // Optional: using your shared method
            const SizedBox(height: 24),
            CustomButton(
              text: "Redeem",
              onPressed: () {
                // Redeem logic here
              },
            ),
          ],
        ),
      ),
    );
  }
}
