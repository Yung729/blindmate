// event_handler.dart
import 'package:blindmate/services/do_mission_service.dart';
import 'package:blindmate/services/do_mission_service.dart';
import 'package:blindmate/models/dataModels/mission_model.dart';

class MissionEventHandler {
  static Future<void> handleGenerateAndStoreMissions() async {
    await generateAndStoreMissions();
  }

  static Future<List<MissionModel>> handleFetchMissions({int limit = 3}) async {
    return await fetchMissionsFromFirebase(limit: limit);
  }

  static Future<List<MissionModel>> handleFetchStatusTrueMissions({int limit = 3}) async {
    return await fetchStatusTrueMissions(limit: limit);
  }

  static Future<List<MissionModel>> handleFetchFinishedTrueMissions({
  int limit = 100,
  required String userId,
}) async {
  return await fetchFinishedTrueMissions(limit: limit, userId: userId);
}


  static Future<void> handleClearMissionList() async {
    await clearMissionList();
  }

  static Future<bool> handleCheckDateAfterCreated() async {
    return await isDateAfterCreated();
  }

  static Future<void> handleSaveMissions(List<MissionModel> missions) async {
    await saveGeneratedMissionsToFirebase(missions);
  }

  static Future<void> handleTrackMissionProgress({
    required String category,
    required String type,
    int actionCount = 1,
    int actionTime = 0,
  }) async {
    await trackUserMissionProgress(
      category: category,
      type: type,
      actionCount: actionCount,
      actionTime: actionTime,
    );
  }

  static Future<void> handleAwardXP(String userId, int xp) async {
    await awardUserXP(userId, xp);
  }
}

// Note: _awardUserXP is private in mission_service.dart.
// If you want to call it from here, expose it publicly or move it to a shared service.
