import 'dart:convert';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/mission_model.dart';
import 'package:intl/intl.dart';

/// Saves a list of generated missions to Firestore.
Future<void> saveGeneratedMissionsToFirebase(
  List<MissionModel> missions,
) async {
  final missionsRef = FirebaseFirestore.instance.collection('mission');

  for (final mission in missions) {
    final missionData = mission.toMap();
    missionData['createdAt'] = FieldValue.serverTimestamp();
    await missionsRef.doc(mission.id).set(mission.toMap());
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

  for (var doc in missions.docs) {
    final data = doc.data();
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
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
    }
  }

  print("Expired outdated missions for user ${currentUser.uid}.");
}

/// Fetches a limited number of missions from Firestore.
Future<List<MissionModel>> fetchMissionsFromFirebase({int limit = 3}) async {
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
          ) // Filter by assignedUser
          .limit(limit)
          .get();

  print(
    "Fetched missions assigned to current user: ${querySnapshot.docs.length}",
  );

  return querySnapshot.docs
      .map(
        (doc) => MissionModel.fromMap(doc.data(), doc.id),
      ) // ✅ Includes doc.id
      .toList();
}

Future<List<MissionModel>> fetchStatusTrueMissions({int limit = 3}) async {
  final allMissions = await fetchMissionsFromFirebase(limit: limit);
  final filtered = allMissions.where((m) => m.status == true).toList();

  print("Filtered missions with status == true: ${filtered.length}");
  return filtered;
}

Future<List<MissionModel>> fetchFinishedTrueMissions({
  int limit = 100,
  required String userId,
}) async {
  print('Fetching missions for user: $userId');
  final snapshot =
      await FirebaseFirestore.instance
          .collection('mission')
          .where('assignedUser', isEqualTo: userId) // ✅ filter by userId
          .where('finished', isEqualTo: true)
          .limit(limit)
          .get();

  print('Query completed. Found ${snapshot.docs.length} finished missions.');

  return snapshot.docs
      .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
      .toList();
}

/// Main function to generate missions, store in Firebase, and update app state.
Future<void> generateAndStoreMissions() async {
  try {
    bool shouldRegenerate = await isDateAfterCreated();

    if (shouldRegenerate) {
      await clearMissionList();
    }

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
          e['finished'] = false;
          e['assignedUser'] = assignedUserId;
          e['progress'] = 0;
          // e['createdAt'] = FieldValue.serverTimestamp();
          return MissionModel.fromMap(e, e['id']);
        }).toList();

    // 2. Save generated missions to Firebase
    await saveGeneratedMissionsToFirebase(missions);

    // 3. Fetch back from Firebase (optional sync step)
    final missionsFromFirebase = await fetchMissionsFromFirebase(limit: 3);
    print('Fetched missions from Firebase: $missionsFromFirebase');

    // 4. Update state
    //   missionListState.setMissionList(missionsFromFirebase);
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
