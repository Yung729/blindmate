import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/viewmodels/eventHandlers/do_mission_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/views/UIComponents/crystal_box.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/mission_field.dart';
import 'package:blindmate/views/screens/mission_history_screen.dart';
import 'package:blindmate/views/screens/redeem_reward_screen.dart';
import 'package:blindmate/views/screens/mission_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/user_model.dart';

class DoMissionScreen extends StatefulWidget {
  final UserModel user;
  const DoMissionScreen({super.key, required this.user});

  @override
  _DoMissionScreenState createState() => _DoMissionScreenState();

  // static Future<UserModel?> fetchUserData() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return null;
  //   final doc =
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(user.uid)
  //           .get();
  //   if (!doc.exists) return null;

  //   return UserModel.fromMap(doc.data()!, doc.id);
  // }
}

class _DoMissionScreenState extends State<DoMissionScreen> {
  UserModel? _currentUser;
  List<MissionModel> _missions = [];
  MissionEventHandler _doMissionHandler = MissionEventHandler();

  @override
  void initState() {
    super.initState();
    print("initState called");
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = context.read<AuthState>().currentUser;
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _currentUser = user;
        });
      }
      if (user != null) {
        final missions = await _doMissionHandler.handleFetchStatusTrueMissions(user.userId);
        if (mounted) {
          setState(() {
            _missions = missions;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Text(
                            '三',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => MissionHistoryScreen(
                                      user: _currentUser!,
                                    ),
                              ),
                            );
                          },
                        ),
                        buildCrystalBox('${_currentUser!.fragmentNumber}'),
                      ],
                    ),
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
                      (mission) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => MissionDetailScreen(mission: mission),
                            ),
                          );
                        },
                        child: MissionField(
                          mission: mission,
                          isCurrentMission: false,
                        ),
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
