import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/viewmodels/dataBinding/do_mission_data_binding.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';

class MissionEventHandler {
  final MissionDataBinding _missionDataBinding;

  MissionEventHandler({required MissionState missionState}) 
      : _missionDataBinding = MissionDataBinding(missionState: missionState);

  /// Initialize mission data
  Future<void> initialize() async {
    await _missionDataBinding.initialize();
  }
  
  /// Get active missions from state
  List<MissionModel> getActiveMissions() {
    return _missionDataBinding.activeMissions;
  }
  
  /// Get finished missions from state
  List<MissionModel> getFinishedMissions() {
    return _missionDataBinding.finishedMissions;
  }
  
  /// Refresh missions from Firebase
  Future<void> refreshMissions() async {
    await _missionDataBinding.refreshMissions();
  }
  
  /// Track mission progress for actions
  Future<void> trackMissionProgress({
    required String category,
    required String type,
    int actionCount = 1,
    int actionTime = 0,
    String? actionType,
  }) async {
    await _missionDataBinding.trackMissionProgress(
      category: category,
      type: type,
      actionCount: actionCount,
      actionTime: actionTime,
      actionType: actionType,
    );
  }
}
