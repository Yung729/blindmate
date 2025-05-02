import 'dart:convert';
import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
// import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/mission_model.dart';
import 'package:intl/intl.dart';

class MissionService {
  UserModel? _currentUser;
  String? userId;
  /// Saves a list of generated missions to Firestore.
  Future<void> saveGeneratedMissionsToFirebase(
    List<MissionModel> missions,
  ) async {
    final missionsRef = FirebaseFirestore.instance.collection('mission');

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
            .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var doc in missions.docs) {
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) continue;

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

    print("No missions created today. Regeneration required.");
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int updatedCount = 0;
    List<String> expiredMissionIds = [];

    for (var doc in missions.docs) {
      // final data = doc.data();
      final createdAtTimestamp = doc.data()['createdAt'] as Timestamp?;
      if (createdAtTimestamp == null) {
        // If no createdAt, expire it by default
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

  // 1. Fetch all user missions (no filters, no limits)
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
      "Fetched missions assigned to current user: ${querySnapshot.docs.length}",
    );

    return querySnapshot.docs
        .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 2. Apply a limit to the missions list fetched from fetchAllUserMissions
  Future<List<MissionModel>> fetchLimitedUserMissions({
    int limit = 3,
  }) async {
    final allMissions = await fetchAllUserMissions(); // Get all missions first
    if (allMissions.length > limit) {
      return allMissions.sublist(0, limit); // Apply the limit to the list
    }
    return allMissions; // Return all if no limit is exceeded
  }

  // 3. Apply `status == true` filter to the missions list fetched from fetchAllUserMissions
  Future<List<MissionModel>> fetchStatusTrueMissions() async {
    final allMissions =
        await fetchLimitedUserMissions(); // Get all missions first
    final filtered =
        allMissions
            .where((m) => m.status == true)
            .toList(); // Filter by status == true

    print("Filtered missions with status == true: ${filtered.length}");

    return filtered;
  }

  // 4. Apply `finished == true` filter to the missions list fetched from fetchAllUserMissions
  Future<List<MissionModel>> fetchFinishedTrueMissions() async {
    final allMissions = await fetchAllUserMissions(); // Get all missions first
    final filtered =
        allMissions
            .where((m) => m.finished == true)
            .toList(); // Filter by finished == true

    print("Filtered missions with finished == true: ${filtered.length}");

    return filtered;
  }

  Future<bool> alreadyGeneratedToday() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return true;

    final doc =
        await FirebaseFirestore.instance
            .collection('generationLog')
            .doc(currentUser.uid)
            .get();

    if (!doc.exists) return false;

    final lastGenerated = (doc.data()?['date'] as Timestamp?)?.toDate();
    if (lastGenerated == null) return false;

    final today = DateTime.now();
    final isSameDay =
        today.year == lastGenerated.year &&
        today.month == lastGenerated.month &&
        today.day == lastGenerated.day;

    return isSameDay;
  }

  Future<void> updateGenerationLog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('generationLog')
        .doc(currentUser.uid)
        .set({'date': DateTime.now()});
  }

  /// Main function to generate missions, store in Firebase, and update app state.
  Future<void> generateAndStoreMissions() async {
    try {
      bool shouldRegenerate = await isDateAfterCreated();
      final alreadyGenerated = await alreadyGeneratedToday();
      if (alreadyGenerated) {
        print('🛑 Missions already generated today. Skipping.');
        return;
      }

      if (shouldRegenerate) {
        await clearMissionList();
      }
      print("Should regenerate missions today? $shouldRegenerate");

      // 1. Generate missions with Gemini
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
          currentUser?.uid ?? ''; // Use UID, fallback to empty string

      // 2. Build list of MissionModel with added fields
      final missions =
          (parsed['missions'] as List).map((e) {
            e['status'] = true;
            // e['finished'] = false;
            e['assignedUser'] = assignedUserId;
            e['progress'] = 0;
            // e['createdAt'] = FieldValue.serverTimestamp();
            return MissionModel.fromMap(e, e['id']);
          }).toList();

      // 2. Save generated missions to Firebase
      await saveGeneratedMissionsToFirebase(missions);

      // 3. Fetch back from Firebase (optional sync step)
      final missionsFromFirebase = await fetchLimitedUserMissions(limit: 3);
      print('Fetched missions from Firebase: $missionsFromFirebase');

      await updateGenerationLog(); // ✅ Mark generation done for today
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
    final missionsRef = FirebaseFirestore.instance.collection('mission');

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

  Future<UserReward?> fetchUserRewards(String userId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('user_reward')
              .where('userId', isEqualTo: userId)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      return UserReward.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print("Error fetching user rewards: $e");
      return null;
    }
  }

  Future<List<RewardModel>> fetchUniqueRedeemedRewards(UserReward userReward) async {
  try {
    // Step 1: Get the redeemed rewards from userReward
    List redeemedRewardIds = userReward.redeemedRewards;
    
    // Step 2: Store all redeemedReward IDs in a list (no duplicates here yet)
    List<RewardModel> allFetchedRewards = [];

    // Step 3: Retrieve all RewardModels for each redeemedReward ID
    for (String rewardId in redeemedRewardIds) {
      RewardModel? rewardModel = await fetchRewardById(rewardId);
      if (rewardModel != null) {
        allFetchedRewards.add(rewardModel);
      }
    }

    // Step 4: Remove duplicates based on redeemRewardId
    Set<String> seenIds = {};
    List<RewardModel> uniqueRewards = allFetchedRewards.where((reward) {
      bool seen = seenIds.contains(reward.redeemRewardId);
      if (!seen) seenIds.add(reward.redeemRewardId);
      return !seen;
    }).toList();

    // Step 5: Return the unique list of RewardModel
    return uniqueRewards;

  } catch (e) {
    print("Error fetching unique rewards: $e");
    return [];
  }
}

Future<RewardModel?> fetchRewardById(String rewardId) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
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

  void assignCurrentUserId(UserModel? user) {
    if (user != null) {
      _currentUser = user;
      userId = user.userId;
      print("Assigned UserId: $userId");
    } else {
      print("No current user found.");
    }
  }
}
