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
import 'package:blindmate/viewmodels/eventHandlers/auth_event_handler.dart';
import 'package:blindmate/viewmodels/dataBinding/auth_data_binding.dart';

class DoMissionScreen extends StatefulWidget {
  final UserModel user;
  const DoMissionScreen({super.key, required this.user});

  @override
  _DoMissionScreenState createState() => _DoMissionScreenState();
}

class _DoMissionScreenState extends State<DoMissionScreen> {
  late AuthEventHandler _authEventHandler;
  UserModel? _currentUser;
  late MissionEventHandler _missionEventHandler;
  bool _isLoading = true;
  double _rewardRate = 1.0; // Default reward rate

  @override
  void initState() {
    super.initState();
    print("DoMissionScreen initState called");

    // Initialize the AuthEventHandler with required arguments
    final authState = context.read<AuthState>();
    final authDataBinding = AuthDataBinding();
    _authEventHandler = AuthEventHandler(authState, authDataBinding);

    _initialize();
  }

  Future<void> _initialize() async {
    // Get user from auth state
    await _authEventHandler.fetchUserData(context);
    final user = context.read<AuthState>().currentUser;

    // Setup event handler with state from provider
    final missionState = Provider.of<MissionState>(context, listen: false);
    _missionEventHandler = MissionEventHandler(missionState: missionState);

    // Initialize mission data
    await _missionEventHandler.initialize();

    // Fetch reward rate from the first active mission (if available)
    if (missionState.activeMissions.isNotEmpty) {
      try {
        _rewardRate = await missionState.activeMissions.first.getRewardRate();
      } catch (e) {
        print("Error fetching reward rate: $e");
        _rewardRate = 1.0; // Fallback to default rate
      }
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMissions() async {
    await _missionEventHandler.refreshMissions();
    // Refresh reward rate
    final missionState = Provider.of<MissionState>(context, listen: false);
    if (missionState.activeMissions.isNotEmpty) {
      try {
        _rewardRate = await missionState.activeMissions.first.getRewardRate();
      } catch (e) {
        print("Error refreshing reward rate: $e");
        _rewardRate = 1.0; // Fallback to default rate
      }
    }
    if (!mounted) return; // Prevent setState after dispose
    setState(() {}); // Safe
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
                  Row(
                    children: [
                      // History Icon Button
                      IconButton(
                        icon: const Icon(Icons.history, size: 24),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MissionHistoryScreen(user: _currentUser!),
                            ),
                          ).then((_) => _refreshMissions());
                        },
                      ),
                      // Reward Rate Button
                      GestureDetector(
                        onTap: () {
                          // Show a dialog with reward rate details
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Reward Rate"),
                              content: Text(
                                "Your current reward rate is ${_rewardRate.toStringAsFixed(1)}x, based on your level. Every 10 levels, your reward rate increases by 0.5x!",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Text(
                            "Reward Rate: ${_rewardRate.toStringAsFixed(1)}x",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Crystal Box
                  buildCrystalBox('${_currentUser!.fragmentNumber}'),
                ],
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 60),
              const Text(
                "Daily Mission",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (activeMissions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
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
                      const SizedBox(height: 20),
                      CustomButton(
                        text: "Rewards",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RedeemRewardScreen(user: _currentUser!),
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