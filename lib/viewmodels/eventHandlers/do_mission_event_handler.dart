// import 'package:blindmate/dataBindings/do_mission_data_binding.dart';
import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:blindmate/viewmodels/dataBinding/do_mission_data_binding.dart';

class MissionEventHandler {
  final DoMissionDataBinding _missionBinding = DoMissionDataBinding();

  Future<void> handleGenerateAndStoreMissions() async {
    await _missionBinding.generateAndStoreMissionsIfNeeded();
  }

  Future<List<MissionModel>> handleFetchMissions({int limit = 3}) async {
    return await _missionBinding.fetchAllUserMissionsWithLimit(limit: limit);
  }

  Future<List<MissionModel>> handleFetchStatusTrueMissions({int limit = 3}) async {
    return await _missionBinding.loadActiveMissions();
  }

  Future<List<MissionModel>> handleFetchFinishedTrueMissions({
  int limit = 100,
  required String userId,
}) async {
  // Pass userId to the data binding method
  return await _missionBinding.loadFinishedMissions(userId, limit: limit);
}


  Future<void> handleClearMissionList() async {
    await _missionBinding.clearMissionList();
  }

  Future<bool> handleCheckDateAfterCreated() async {
    return await _missionBinding.isDateAfterCreated();
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

  Future<void> handleAwardXP(String userId, int xp) async {
    await _missionBinding.awardXP(userId, xp);
  }

  void handleUserLogin(UserModel user) {
    _missionBinding.setCurrentUser(user);
  }

  Future<List<RewardModel>> handleFetchRewards(UserModel user) async {
    return await _missionBinding.getUserRewards(user.userId);
  }
}
