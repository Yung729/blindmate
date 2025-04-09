import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';
import 'matching_screen.dart';

class DoMissionScreen extends StatefulWidget {
  const DoMissionScreen({super.key});

  @override
  _DoMissionScreenState createState() => _DoMissionScreenState();

  static Future<UserModel?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
  }
}

class _DoMissionScreenState extends State<DoMissionScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DoMissionScreen.fetchUserData();
    setState(() {
      _currentUser = user;
    });
  }

  Widget _buildMissionField(String missionName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ongoing Mission Progress",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          missionName,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.black, width: 1.0),
          ),
        )
      ],
    );
  }

  Widget _buildCrystalBox(String text) {
    return Align(
      alignment: Alignment.topRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image.asset('assets/crystal.png', height: 50), // Add your crystal image asset here
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16.0),
        alignment: Alignment.topCenter,
        child: 
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCrystalBox('111'),
            _buildMissionField('Mission 1'),
            SizedBox(height: 20),
            // _buildMissionField('Mission 2'),
            // SizedBox(height: 20),
            // _buildMissionField('Mission 3'),
          ],
        ),
      ),
    );
  }
}
