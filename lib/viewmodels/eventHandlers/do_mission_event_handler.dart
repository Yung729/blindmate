import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/viewmodels/dataBinding/do_mission_data_binding.dart';

class MissionEventHandler {
  final DoMissionDataBinding _missionBinding = DoMissionDataBinding();

  Future<void> handleGenerateAndStoreMissions() async {
    await _missionBinding.generateAndStoreMissionsIfNeeded();
  }

  Future<List<MissionModel>> handleFetchStatusTrueMissions(String userId) async {
    return await _missionBinding.loadActiveMissions(userId);
  }

  Future<List<MissionModel>> getFinishedMissions({
  int limit = 100,
  required String userId,
}) async {
  // Pass userId to the data binding method
  return await _missionBinding.loadFinishedMissions(userId, limit: limit);
}

  Future<void> handleTrackMissionProgress({
    required String category,
    required String type,
    int actionCount = 1,
    int actionTime = 0,
  }) async {
    await _missionBinding.trackProgress(
      category: category,
      type: type,
      actionCount: actionCount,
      actionTime: actionTime,
    );
  }

  // void handleUserLogin(UserModel user) {
  //   _missionBinding.setCurrentUser(user);
  // }

  Future<List<RewardModel>> handleFetchRewards(UserModel user) async {
    return await _missionBinding.getUserRewards(user.userId);
  }
}
