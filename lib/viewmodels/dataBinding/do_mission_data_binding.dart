import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:blindmate/services/do_mission_service.dart';
import 'package:flutter/material.dart';

class DoMissionDataBinding {
  final List<MissionModel> _missions = [];
  final List<MissionModel> _finishedMissions = [];
  final missionService = MissionService();

  List<MissionModel> get missions => _missions;
  List<MissionModel> get finishedMissions => _finishedMissions;

  Future<void> initialize() async {
    await generateAndStoreMissionsIfNeeded();
    await loadActiveMissions();
  }

  Future<void> generateAndStoreMissionsIfNeeded() async {
    try {
      final shouldGenerate = await missionService.isDateAfterCreated();
      if (shouldGenerate) {
        await clearMissionList();
        await missionService.generateAndStoreMissions();
      }
    } catch (e) {
      debugPrint("❌ Failed to generate missions: $e");
    }
  }

  Future<void> clearMissionList() async {
    try {
      await missionService.clearMissionList();
      _missions.clear();
      _finishedMissions.clear();
      debugPrint("✅ Mission list cleared.");
    } catch (e) {
      debugPrint("❌ Failed to clear mission list: $e");
    }
  }

  Future<List<MissionModel>> loadActiveMissions() async {
    try {
      final active = await missionService.fetchStatusTrueMissions();
      _missions
        ..clear()
        ..addAll(active);
      return active;
    } catch (e) {
      debugPrint("❌ Failed to load active missions: $e");
      return [];
    }
  }

  Future<List<MissionModel>> loadFinishedMissions(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final finished = await missionService.fetchFinishedTrueMissions();
      _finishedMissions
        ..clear()
        ..addAll(finished);
      return finished;
    } catch (e) {
      debugPrint("❌ Failed to load finished missions: $e");
      return [];
    }
  }

  Future<List<MissionModel>> fetchAllUserMissionsWithLimit({
    int limit = 100,
  }) async {
    try {
      final allMissions = await missionService.fetchLimitedUserMissions(
        limit: limit,
      );
      return allMissions;
    } catch (e) {
      debugPrint("❌ Failed to fetch all user missions: $e");
      return [];
    }
  }

  Future<void> trackProgress({
    required String category,
    required String type,
    int actionCount = 1,
    int actionTime = 0,
  }) async {
    try {
      await missionService.trackUserMissionProgress(
        category: category,
        type: type,
        actionCount: actionCount,
        actionTime: actionTime,
      );
    } catch (e) {
      debugPrint("❌ Failed to track mission progress: $e");
    }
  }

  Future<void> awardXP(String userId, int xp) async {
    try {
      await missionService.awardUserXP(userId, xp);
    } catch (e) {
      debugPrint("❌ Failed to award XP: $e");
    }
  }

  Future<bool> isDateAfterCreated() async {
    try {
      return await missionService
          .isDateAfterCreated(); // Calling the service function here
    } catch (e) {
      debugPrint("❌ Failed to check date: $e");
      return false;
    }
  }

  void setCurrentUser(UserModel? user) {
    missionService.assignCurrentUserId(user);
  }

  Future<List<RewardModel>> getUserRewards(String userId) async {
    UserReward? userReward = await missionService.fetchUserRewards(
      userId,
    );
    if (userReward != null) {
      return missionService.fetchUniqueRedeemedRewards(userReward);
    } else {
      return []; // or throw an exception if null is unacceptable
    }
  }
}
