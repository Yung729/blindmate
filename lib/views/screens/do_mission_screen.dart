import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/services/do_mission_service.dart';
import 'package:blindmate/viewmodels/eventHandlers/do_mission_event_handler.dart';
import 'package:blindmate/views/UIComponents/crystal_box.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/mission_field.dart';
import 'package:blindmate/views/screens/redeem_reward_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';

class DoMissionScreen extends StatefulWidget {
  final UserModel user;

  const DoMissionScreen({super.key, required this.user});

  @override
  _DoMissionScreenState createState() => _DoMissionScreenState();

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

class _DoMissionScreenState extends State<DoMissionScreen> {
  UserModel? _currentUser;
  List<MissionModel> _missions = [];
  late DoMissionHandler _doMissionHandler;

  @override
  void initState() {
    super.initState();
    print("initState called");
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DoMissionScreen.fetchUserData();
    if (mounted) {
      // Check if widget is still mounted
      setState(() {
        _currentUser = user;
      });
    }
    if (user != null) {
      _doMissionHandler = DoMissionHandler(user: user);

      var missions = await fetchStatusTrueMissions(limit: 3);
      // 👈 use your service

      if (mounted) {
        setState(() {
          _missions = missions;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _currentUser == null
              ? Center(child: CircularProgressIndicator())
              : Container(
                padding: EdgeInsets.only(
                  top: 40.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 48),
                    buildCrystalBox('${_currentUser!.fragmentNumber}'),
                    SizedBox(height: 24),
                    SizedBox(height: 60),
                    Text(
                      "Daily Mission",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 20),
                    ..._missions.map(
                      (mission) => MissionField(
                        mission: mission,
                        isCurrentMission: false,
                      ),
                    ),
                    SizedBox(height: 20),
                    CustomButton(
                      text: "reward",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RedeemRewardScreen(user: _currentUser!),
                          ),
                        ).then((_) {
                          // ✅ Refresh the user data when coming back
                          _loadUserData();
                        });
                        ;
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
