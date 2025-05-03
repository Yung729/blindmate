import 'dart:convert';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/mission_model.dart';

class MissionService {
  final missionsRef = FirebaseFirestore.instance.collection('mission');
  String? userId;

  /// Saves a list of generated missions to Firestore.
  Future<void> saveGeneratedMissionsToFirebase(
    List<MissionModel> missions,
  ) async {
    for (final mission in missions) {
      final missionData = mission.toMap();
      missionData['createdAt'] = DateTime.now();
      await missionsRef.add(missionData);
    }
  }

  Future<bool> isDateAfterCreated() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("No user is logged in.");

    final missions =
        await FirebaseFirestore.instance
            .collection('mission')
            .where('assignedUser', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final createdAt =
        missions.docs.isEmpty
            ? null
            : (missions.docs.first.data()['createdAt'] as Timestamp?)?.toDate();
    if (createdAt != null) {
      final createdDate = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );
      if (today.isAtSameMomentAs(createdDate)) {
        print("Found a mission already created today. Skip regeneration.");
        return false;
      }
    }

    print(
      "No missions found for user ${currentUser.uid}. Regeneration required.",
    );
    return true;
  }

  Future<void> clearMissionList() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("No user is logged in.");
    }

    final missions =
        await FirebaseFirestore.instance
            .collection('mission')
            .where('assignedUser', isEqualTo: currentUser.uid)
            .get();

    int updatedCount = 0;
    List<String> expiredMissionIds = [];

    for (var doc in missions.docs) {
      final createdAtTimestamp = doc.data()['createdAt'] as Timestamp?;
      if (createdAtTimestamp == null) {
        await doc.reference.update({'status': false});
        continue;
      }

      final createdAt = createdAtTimestamp.toDate();
      final now = DateTime.now();

      // Compare only date (ignoring time)
      final createdDateOnly = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );
      final nowDateOnly = DateTime(now.year, now.month, now.day);

      if (nowDateOnly.isAfter(createdDateOnly)) {
        await doc.reference.update({'status': false});
        expiredMissionIds.add(doc.id);
        updatedCount++;
      }
    }

    print("✅ Expired ${updatedCount} missions created before today.");
    if (expiredMissionIds.isNotEmpty) {
      print("🗂️ Updated mission IDs: ${expiredMissionIds.join(', ')}");
    }

    print("Expired outdated missions for user ${currentUser.uid}.");
  }

  Future<List<MissionModel>> fetchAllUserMissions() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception("No user is logged in.");
    }

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('mission')
            .where(
              'assignedUser',
              isEqualTo: currentUser.uid,
            ) // Fetch all missions for user
            .get(); // No limit or filtering here

    print(
      "Fetched missions assigned to current user {$currentUser.uid} : ${querySnapshot.docs.length}",
    );

    return querySnapshot.docs
        .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<MissionModel>> fetchStatusTrueMissions(String userId) async {
    final querySnapshot =
        await missionsRef
            .where('assignedUser', isEqualTo: userId)
            .where('status', isEqualTo: true)
            .get();
    return querySnapshot.docs
        .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<MissionModel>> fetchFinishedMissions() async {
    final allMissions = await fetchAllUserMissions(); // Get all missions first
    final filtered =
        allMissions
            .where((m) => m.finished == true)
            .where((m) => m.status == true)
            .toList(); // Filter by finished == true

    print("Filtered missions with finished == true: ${filtered.length}");

    return filtered;
  }

  /// Main function to generate missions, store in Firebase, and update app state.
  Future<void> generateAndStoreMissions() async {
    try {
      bool shouldRegenerate = await isDateAfterCreated();

      if (shouldRegenerate) {
        await clearMissionList();
      }
      print("Should regenerate missions today? $shouldRegenerate");

      final geminiService = GeminiModerationService();
      final geminiJson = await geminiService.generateMissionJsonFromPrompt();

      final parsed = json.decode(geminiJson);

      if (parsed['missions'] == null || parsed['missions'] is! List) {
        throw Exception(
          'No missions found in the Gemini response or invalid format',
        );
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final assignedUserId =
          currentUser?.uid ?? ''; 

      // 2. Build list of MissionModel with added fields
      final missions =
          (parsed['missions'] as List).map((e) {
            e['status'] = true;
            e['assignedUser'] = assignedUserId;
            e['progress'] = 0;
            return MissionModel.fromMap(e, e['id']);
          }).toList();

      // 2. Save generated missions to Firebase
      await saveGeneratedMissionsToFirebase(missions);

    } catch (e) {
      print('❌ Error during mission generation: $e');
      rethrow;
    }
  }

  // Function to award XP to the user when the mission is finished
  Future<void> awardUserXP(String userId, int xp) async {
    try {
      // Update the user's fragmentNumber (XP) in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fragmentNumber': FieldValue.increment(
          xp,
        ), // Add XP to user's fragmentNumber
      });
      print("Awarded $xp XP to user: $userId");
    } catch (e) {
      print("Error awarding XP to the user: $e");
    }
  }

  Future<void> trackUserMissionProgress({
    required String category,
    required String type,
    int actionCount = 1,
    int actionTime = 0,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception("No user is logged in.");
    }

    final missions =
        await missionsRef
            .where('assignedUser', isEqualTo: currentUser.uid)
            .where('category', isEqualTo: category)
            .where('type', isEqualTo: type)
            .where('status', isEqualTo: true)
            .where('finished', isEqualTo: false)
            .get();

    if (missions.docs.isEmpty) {
      print(
        "No missions found for user ${currentUser.uid} with category: $category and type: $type.",
      );
      return;
    }

    for (var mission in missions.docs) {
      // Get mission data
      final missionData = mission.data();
      final currentProgress = missionData['progress'] ?? 0;
      final target = missionData['requirements']['target'] ?? 0;
      final rewardXp = missionData['rewards']['xp'] ?? 0;

      if (currentProgress + (type == 'time' ? actionTime : actionCount) >=
          target) {
        // Mark mission as finished
        await missionsRef.doc(mission.id).update({
          'progress': target, // Set progress to target value
          'finished': true, // Mark as finished
        });

        // Award the user XP (e.g., increment their 'fragmentNumber' field in the user document)
        await awardUserXP(currentUser.uid, rewardXp);

        print("Mission completed: ${mission.id}, XP awarded: $rewardXp");
      } else {
        // Update progress incrementally
        await missionsRef.doc(mission.id).update({
          'progress': FieldValue.increment(
            type == 'time' ? actionTime : actionCount,
          ),
        });
        print("Updated mission progress for mission ID: ${mission.id}");
      }
    }

    //   if (type == 'time') {
    //     await missionsRef.doc(mission.id).update({
    //       'progress': FieldValue.increment(actionTime),
    //     });
    //     print("Updated mission progress (time) for mission ID: ${mission.id}");
    //   } else if (type == 'action') {
    //     await missionsRef.doc(mission.id).update({
    //       'progress': FieldValue.increment(actionCount),
    //     });
    //     print("Updated mission progress (action) for mission ID: ${mission.id}");
    //   }
    // }
  }

  Future<RewardModel?> fetchRewardById(String rewardId) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('reward')
              .doc(rewardId)
              .get();

      if (docSnapshot.exists) {
        return RewardModel.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print("Error fetching reward by ID: $e");
    }
    return null;
  }
}
