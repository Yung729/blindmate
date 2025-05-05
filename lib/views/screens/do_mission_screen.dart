import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/viewmodels/eventHandlers/mission_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
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
  late MissionEventHandler _missionEventHandler;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("DoMissionScreen initState called");
    _initialize();
  }

  Future<void> _initialize() async {
    // Get user from auth state
    final user = context.read<AuthState>().currentUser;
    
    // Setup event handler with state from provider
    final missionState = Provider.of<MissionState>(context, listen: false);
    _missionEventHandler = MissionEventHandler(missionState: missionState);
    
    // Initialize mission data
    await _missionEventHandler.initialize();
    
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMissions() async {
    await _missionEventHandler.refreshMissions();
    setState(() {}); // Trigger rebuild to show updated missions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading || _currentUser == null
          ? Center(child: CircularProgressIndicator())
          : _buildMissionContent(),
    );
  }

  Widget _buildMissionContent() {
    // Use Consumer for reactive UI updates
    return Consumer<MissionState>(
      builder: (context, missionState, child) {
        final activeMissions = missionState.activeMissions;
        
        return Container(
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
                          builder: (_) => MissionHistoryScreen(
                            user: _currentUser!,
                          ),
                        ),
                      ).then((_) => _refreshMissions());
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (activeMissions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "No active missions available today.",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      else
                        ...activeMissions.map(
                          (mission) => GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MissionDetailScreen(mission: mission),
                                ),
                              ).then((_) {
                                // Refresh missions after coming back from details
                                _refreshMissions();
                              });
                            },
                            child: MissionField(
                              mission: mission,
                              isCurrentMission: false,
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                      CustomButton(
                        text: "Rewards",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RedeemRewardScreen(
                                user: _currentUser!,
                              ),
                            ),
                          ).then((_) {
                            // Refresh the user data when coming back
                            _refreshMissions();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
