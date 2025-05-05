import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:blindmate/services/do_mission_service.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MissionDataBinding {
  final MissionService _missionService = MissionService();
  final MissionState _missionState;

  MissionDataBinding({required MissionState missionState}) : _missionState = missionState;

  // Getters to access state
  List<MissionModel> get activeMissions => _missionState.activeMissions;
  List<MissionModel> get finishedMissions => _missionState.finishedMissions;

  /// Initialize mission data - load active missions and finished missions
  Future<void> initialize() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Check if missions need to be generated today
      await generateDailyMissionsIfNeeded();
      
      // Load active missions
      await loadActiveMissions(currentUser.uid);
      
      // Load finished missions
      await loadFinishedMissions(currentUser.uid);
    } catch (e) {
      debugPrint("❌ Failed to initialize missions: $e");
    }
  }

  /// Load active missions for the user and update state
  Future<void> loadActiveMissions(String userId) async {
    try {
      final activeMissions = await _missionService.fetchStatusTrueMissions(userId);
      _missionState.setActiveMissions(activeMissions);
      return;
    } catch (e) {
      debugPrint("❌ Failed to load active missions: $e");
    }
  }

  /// Load finished missions for the user and update state
  Future<void> loadFinishedMissions(String userId, {int limit = 100}) async {
    try {
      final finishedMissions = await _missionService.fetchFinishedMissions(userId);
      _missionState.setFinishedMissions(finishedMissions);
      return;
    } catch (e) {
      debugPrint("❌ Failed to load finished missions: $e");
    }
  }

  /// Generate new missions if needed (once per day)
  Future<void> generateDailyMissionsIfNeeded() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // The generateAndStoreMissions method already has all the necessary checks
      // to determine if missions need to be generated
      await _missionService.generateAndStoreMissions();
    } catch (e) {
      debugPrint("❌ Failed to generate daily missions: $e");
    }
  }

  /// Track progress for missions matching category and type
  Future<void> trackMissionProgress({
    required String category, 
    required String type,
    int actionCount = 1,
    int actionTime = 0,
  }) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Find active missions that match the category and type
      final matchingMissions = _missionState.activeMissions.where((mission) => 
        mission.category == category && 
        mission.type == type && 
        !mission.finished
      ).toList();
      
      if (matchingMissions.isEmpty) return;
      
      // Update each matching mission
      for (final mission in matchingMissions) {
        // Calculate new progress
        final progressIncrement = mission.type == 'time' ? actionTime : actionCount;
        final newProgress = mission.progress + progressIncrement;
        final isFinished = newProgress >= mission.requirements.target;
        final finalProgress = isFinished ? mission.requirements.target : newProgress;
        
        // Update the mission in Firebase
        await _missionService.updateMissionProgress(
          mission.id, 
          finalProgress, 
          isFinished
        );
        
        // Update the mission in state
        _missionState.updateMission(
          mission.id, 
          finalProgress, 
          isFinished
        );
        
        // Award XP if finished
        if (isFinished) {
          await _missionService.awardUserFragment(currentUser.uid, mission.rewards.xp);
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to track mission progress: $e");
    }
  }
  
  /// Refresh all missions data
  Future<void> refreshMissions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      await loadActiveMissions(currentUser.uid);
      await loadFinishedMissions(currentUser.uid);
    } catch (e) {
      debugPrint("❌ Failed to refresh missions: $e");
    }
  }
}
