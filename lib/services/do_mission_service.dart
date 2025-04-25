import 'dart:convert';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/mission_model.dart';

/// Loads prompt from assets and sends it to Gemini API.
Future<String> callGeminiToGenerateMissions() async {
  const apiKey = 'AIzaSyCpduqdv3nfhxOZ4bF99Mm2YEuYc3OLAgs'; // 🔐 Replace securely in production
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  final promptFilePath = '../../assets/MissionGenerationPrompt.txt';
  final prompt = await rootBundle.loadString('assets/mission_prompt.txt');
  final response = await model.generateContent([Content.text(prompt)]);

  final jsonResult = response.text;
  if (jsonResult == null || jsonResult.isEmpty) {
    throw Exception('Gemini returned an empty result');
  }

  return jsonResult;
}

/// Saves a list of generated missions to Firestore.
Future<void> saveGeneratedMissionsToFirebase(List<MissionModel> missions) async {
  final missionsRef = FirebaseFirestore.instance.collection('mission');

  for (final mission in missions) {
    await missionsRef.doc(mission.id).set(mission.toMap());
  }
}

/// Fetches a limited number of missions from Firestore.
Future<List<MissionModel>> fetchMissionsFromFirebase({int limit = 3}) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('mission')
      .limit(limit)
      .get();

  return querySnapshot.docs
      .map((doc) => MissionModel.fromMap(doc.data(), doc.id)) // ✅ Includes doc.id
      .toList();
}

/// Main function to generate missions, store in Firebase, and update app state.
Future<void> generateAndStoreMissions(MissionListState missionListState) async {
  try {
    // 1. Generate missions with Gemini
    final geminiJson = await callGeminiToGenerateMissions();
    final parsed = json.decode(geminiJson);

    final currentUser = FirebaseAuth.instance.currentUser;
    final assignedUserId = currentUser?.uid ?? ''; // Use UID, fallback to empty string

    // 2. Build list of MissionModel with added fields
    final missions = (parsed['missions'] as List)
        .map((e) {
          e['selected'] = false;
          e['finished'] = false;
          e['assignedUser'] = assignedUserId;
          e['progress'] = 0;
          return MissionModel.fromMap(e, e['id']);
        })
        .toList();

    // 2. Save generated missions to Firebase
    await saveGeneratedMissionsToFirebase(missions);

    // 3. Fetch back from Firebase (optional sync step)
    final missionsFromFirebase = await fetchMissionsFromFirebase(limit: 3);

    // 4. Update state
    missionListState.setMissionList(missionsFromFirebase);
  } catch (e) {
    print('❌ Error during mission generation: $e');
    rethrow;
  }
}
