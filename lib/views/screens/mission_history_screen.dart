import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/viewmodels/eventHandlers/do_mission_event_handler.dart';

class MissionHistoryScreen extends StatefulWidget {
  final UserModel user;
  const MissionHistoryScreen({super.key, required this.user});

  @override
  _MissionHistoryScreenState createState() => _MissionHistoryScreenState();
}

class _MissionHistoryScreenState extends State<MissionHistoryScreen> {
  List<MissionModel> _finishedMissions = [];
  bool _isLoading = true;
  final MissionEventHandler _missionEventHandler = MissionEventHandler();

  @override
  void initState() {
    super.initState();
    _loadFinishedMissions();
  }

  Future<void> _loadFinishedMissions() async {
    final missions = await _missionEventHandler.handleFetchFinishedTrueMissions(limit: 100,userId: widget.user.userId,);
    print("Fetched ${missions.length} finished missions."); // Debug print
    setState(() {
      _finishedMissions = missions;
      _isLoading = false;
    });
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
          : _finishedMissions.isEmpty
              ? const Center(child: Text("No completed missions yet."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _finishedMissions.map((mission) {
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
                ),
    );
  }
}
