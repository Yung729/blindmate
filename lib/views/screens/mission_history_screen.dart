import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/viewmodels/eventHandlers/mission_event_handler.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:provider/provider.dart';

class MissionHistoryScreen extends StatefulWidget {
  final UserModel user;
  const MissionHistoryScreen({super.key, required this.user});

  @override
  _MissionHistoryScreenState createState() => _MissionHistoryScreenState();
}

class _MissionHistoryScreenState extends State<MissionHistoryScreen> {
  late MissionEventHandler _missionEventHandler;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Setup event handler with state from provider
    final missionState = Provider.of<MissionState>(context, listen: false);
    _missionEventHandler = MissionEventHandler(missionState: missionState);
    
    // Refresh mission history data
    await _missionEventHandler.refreshMissions();
    
    // Update loading state
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mission History"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMissionHistoryContent(),
    );
  }

  Widget _buildMissionHistoryContent() {
    // Use Consumer to react to state changes
    return Consumer<MissionState>(
      builder: (context, missionState, child) {
        final finishedMissions = missionState.finishedMissions;
        
        if (finishedMissions.isEmpty) {
          return const Center(child: Text("No completed missions yet."));
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: finishedMissions.map((mission) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("${mission.type} mission"),
                        ],
                      ),
                    ),
                    Text(
                      "+${mission.rewards.xp} fragments",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
