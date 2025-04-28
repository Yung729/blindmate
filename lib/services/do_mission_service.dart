import 'dart:convert';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/mission_model.dart';
import 'package:intl/intl.dart';

/// Loads prompt from assets and sends it to Gemini API.
Future<String> callGeminiToGenerateMissions() async {
  const apiKey =
      'AIzaSyCpduqdv3nfhxOZ4bF99Mm2YEuYc3OLAgs'; // 🔐 Replace securely in production
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  final promptFilePath = 'assets/MissionGenerationPrompt.txt';
  final prompt = await rootBundle.loadString(
    'assets/MissionGenerationPrompt.txt',
  );
  final response = await model.generateContent([Content.text(prompt)]);

  var jsonResult = response.text?.trim();

  print('Gemini Response: $jsonResult');

  jsonResult = jsonResult?.replaceAll(RegExp(r'^```json|\n|```'), '');

  if (jsonResult == null || jsonResult.isEmpty) {
    throw Exception('Gemini returned an empty result');
  }

  return jsonResult;
}

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
  if (currentUser == null) {
    throw Exception("No user is logged in.");
  }

  final missions =
      await FirebaseFirestore.instance
          .collection('mission')
          .where('assignedUser', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

  if (missions.docs.isEmpty) {
    print("No missions found. Need to generate.");
    return true;
  }

  final createdAtTimestamp =
      missions.docs.first.data()['createdAt'] as Timestamp?;
  if (createdAtTimestamp == null) {
    print("Mission has no createdAt. Need to generate.");
    return true;
  }

  final createdAt = createdAtTimestamp.toDate();
  final now = DateTime.now();

  final createdDateOnly = DateTime(
    createdAt.year,
    createdAt.month,
    createdAt.day,
  );
  final nowDateOnly = DateTime(now.year, now.month, now.day);

  if (nowDateOnly.isAfter(createdDateOnly)) {
    print(
      "Today's date is after createdAt date. Need to clear and regenerate.",
    );
    return true;
  } else {
    print("Today's date is the same as createdAt date. No need to regenerate.");
    return false;
  }
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
    await doc.reference.delete();
  }

  print("Mission list cleared for user ${currentUser.uid}.");
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

/// Main function to generate missions, store in Firebase, and update app state.
Future<void> generateAndStoreMissions() async {
  try {
    bool shouldRegenerate = await isDateAfterCreated();

    if (shouldRegenerate) {
      await clearMissionList();
    }

    // 1. Generate missions with Gemini
    final geminiJson = await callGeminiToGenerateMissions();
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
          e['selected'] = false;
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
          .where('expiredDate', isGreaterThanOrEqualTo: DateTime.now())
          .get();

  if (missions.docs.isEmpty) {
    print(
      "No missions found for user ${currentUser.uid} with category: $category and type: $type.",
    );
    return;
  }

  for (var mission in missions.docs) {
    if (type == 'time') {
      await missionsRef.doc(mission.id).update({
        'progress': FieldValue.increment(actionTime),
      });
      print("Updated mission progress (time) for mission ID: ${mission.id}");
    } else if (type == 'action') {
      await missionsRef.doc(mission.id).update({
        'progress': FieldValue.increment(actionCount),
      });
      print("Updated mission progress (action) for mission ID: ${mission.id}");
    }
  }
}
