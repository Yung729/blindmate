import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:flutter/material.dart';

class MissionListState with ChangeNotifier {
  // List of available missions (limited to 3)
  List<MissionModel> _missionList = [];
  // Currently selected mission
  String? _currentMission;
  
  List<MissionModel> get missionList => _missionList;
  String? get currentMission => _currentMission;

  // Set the mission list (only take 3)
  void setMissionList(List<MissionModel> missions) {
    _missionList = missions.take(3).toList();
    notifyListeners();
  }

   // Select a mission as current
  void selectMission(String mission) {
    if (_missionList.contains(mission)) {
    _currentMission = mission;
    notifyListeners();
  }
  }

  // Clear the state
  void clear() {
    _missionList = [];
    _currentMission = null;
    notifyListeners();
  }

  //only clear current mission
  void clearCurrentMission(){
    _currentMission = null;
    notifyListeners();
  }

  //only clear mission list
  void clearMissionList(){
    _missionList = [];
    notifyListeners();
  }
}