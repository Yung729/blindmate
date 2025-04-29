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
  // MissionModel? _currentMissionModel;

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
      // if (user.currentMission != null) {
      //   final doc =
      //       await FirebaseFirestore.instance
      //           .collection('missions')
      //           .doc(user.currentMission)
      //           .get();
      //   if (doc.exists) {
      //     setState(() {
      //       _currentMissionModel = MissionModel.fromMap(doc.data()!, doc.id);
      //     });
      //   }
      // } else {
      //   _currentMissionModel = null; // No current mission
      // }
      var missions = await fetchStatusTrueMissions(limit: 3);
      // 👈 use your service

      // if (missions.isEmpty) {
      //   print("Missions empty, generating new ones...");
      //   await generateAndStoreMissions();
      //   missions = await fetchMissionsFromFirebase(
      //     limit: 3,
      //   ); // Fetch again after generating
      // }

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
                    // Center(
                    //   child: Column(
                    //     children: [
                    //       Text(
                    //         "Current Mission",
                    //         style: TextStyle(
                    //           fontSize: 28,
                    //           fontWeight: FontWeight.w900,
                    //         ),
                    //       ),
                    //       SizedBox(height: 24),
                    //       _currentMissionModel == null
                    //           ? Text(
                    //             "No mission selected currently",
                    //             style: TextStyle(color: Colors.grey.shade600),
                    //           )
                    //           : MissionField(
                    //             mission: _currentMissionModel!,
                    //             isCurrentMission:
                    //                 true, // ✅ Mark it as "current"
                    //           ),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: 60),
                    Text(
                      "Daily Mission",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 20),
                    // _buildMissionField('Mission 1'),
                    // SizedBox(height: 25),
                    // // _buildMissionField('Mission 2'),
                    // // SizedBox(height: 20),
                    // // _buildMissionField('Mission 3'),
                    ..._missions.map(
                      (mission) => MissionField(
                        mission: mission,
                        isCurrentMission: false,
                        // onTap: () async {
                        //   if (_currentUser != null) {
                        //     await _doMissionHandler.assignMissionToUser(
                        //       context,
                        //       mission,
                        //     );
                        //     await _loadUserData();
                        //   }
                        // },
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
