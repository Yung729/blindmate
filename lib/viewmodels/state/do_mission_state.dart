import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:flutter/material.dart';

class MissionListState with ChangeNotifier {
  List<MissionModel> _missionList = [];
  String? _currentMission;
  
  List<MissionModel> get missionList => _missionList;
  String? get currentMission => _currentMission;

  void setMissionList(List<MissionModel> missions) {
    _missionList = missions;
    notifyListeners();
  }

  void selectMission(String mission) {
    if (_missionList.contains(mission)) {
    _currentMission = mission;
    notifyListeners();
  }
  }

  void clear() {
    _missionList = [];
    _currentMission = null;
    notifyListeners();
  }

  void clearCurrentMission(){
    _currentMission = null;
    notifyListeners();
  }

  void clearMissionList(){
    _missionList = [];
    notifyListeners();
  }
}