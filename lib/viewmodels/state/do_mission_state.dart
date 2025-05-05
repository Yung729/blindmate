import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:flutter/material.dart';

class MissionState with ChangeNotifier {
  // Active missions that can be progressed
  List<MissionModel> _activeMissions = [];
  
  // Completed missions for history
  List<MissionModel> _finishedMissions = [];
  
  // Getters
  List<MissionModel> get activeMissions => _activeMissions;
  List<MissionModel> get finishedMissions => _finishedMissions;

  // Set active missions (daily missions)
  void setActiveMissions(List<MissionModel> missions) {
    _activeMissions = missions;
    notifyListeners();
  }

  // Add a single active mission
  void addActiveMission(MissionModel mission) {
    if (!_activeMissions.any((m) => m.id == mission.id)) {
      _activeMissions.add(mission);
      notifyListeners();
    }
  }

  // Update a mission's progress
  void updateMission(String missionId, int progress, bool finished) {
    final index = _activeMissions.indexWhere((m) => m.id == missionId);
    
    if (index != -1) {
      // Create a copy of the mission with updated progress
      final updatedMission = MissionModel(
        id: _activeMissions[index].id,
        title: _activeMissions[index].title,
        description: _activeMissions[index].description,
        type: _activeMissions[index].type,
        category: _activeMissions[index].category,
        difficulty: _activeMissions[index].difficulty,
        requirements: _activeMissions[index].requirements,
        rewards: _activeMissions[index].rewards,
        status: _activeMissions[index].status,
        finished: finished,
        assignedUser: _activeMissions[index].assignedUser,
        progress: progress,
        createdAt: _activeMissions[index].createdAt,
      );
      
      // Replace old mission with updated one
      _activeMissions[index] = updatedMission;
      
      // If mission is finished, move it to finishedMissions
      if (finished && !_finishedMissions.any((m) => m.id == missionId)) {
        _finishedMissions.add(updatedMission);
        _activeMissions.removeAt(index);
      }
      
      notifyListeners();
    }
  }

  // Set finished missions (for history)
  void setFinishedMissions(List<MissionModel> missions) {
    _finishedMissions = missions;
    notifyListeners();
  }

  // Add a finished mission to history
  void addFinishedMission(MissionModel mission) {
    if (!_finishedMissions.any((m) => m.id == mission.id)) {
      _finishedMissions.add(mission);
      notifyListeners();
    }
  }

  // Clear all missions
  void clear() {
    _activeMissions = [];
    _finishedMissions = [];
    notifyListeners();
  }

  // Clear only active missions
  void clearActiveMissions() {
    _activeMissions = [];
    notifyListeners();
  }

  // Clear only finished missions
  void clearFinishedMissions() {
    _finishedMissions = [];
    notifyListeners();
  }
}