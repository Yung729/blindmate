import 'dart:convert';
import 'package:blindmate/models/api/gemini_moderation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/mission_model.dart';

class MissionService {
  final missionsRef = FirebaseFirestore.instance.collection('mission');

  /// Saves a list of generated missions to Firestore.
  Future<void> saveGeneratedMissionsToFirebase(
    List<MissionModel> missions,
  ) async {
    for (final mission in missions) {
      final missionData = mission.toMap();
      missionData['createdAt'] = Timestamp.now();
      await missionsRef.add(missionData);
    }
  }

  /// Checks if we need to generate new missions for today
  Future<bool> isDateAfterCreated() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("No user is logged in.");

    // Get today's date (just the date part, no time)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get the most recent mission's creation date
    final missions = await FirebaseFirestore.instance
        .collection('mission')
        .where('assignedUser', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (missions.docs.isEmpty) {
      print("No missions found for user ${currentUser.uid}. Generation required.");
      return true;
    }

    final createdAt = (missions.docs.first.data()['createdAt'] as Timestamp?)?.toDate();
    if (createdAt == null) {
      print("Creation date missing for existing mission. Generation required.");
      return true;
    }
    
    // Compare only date parts
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    if (today.isAtSameMomentAs(createdDate)) {
      print("Found missions already created today. Skip regeneration.");
      return false;
    } else if (today.isAfter(createdDate)) {
      print("Last mission was created before today. Regeneration required.");
      return true;
    } else {
      print("Unexpected date comparison result. Using safe default (no regeneration).");
      return false;
    }
  }

  Future<void> clearMissionList() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("No user is logged in.");
    }

    // Get today's date (just the date part, no time)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final missions = await FirebaseFirestore.instance
        .collection('mission')
        .where('assignedUser', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: true)
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

      // Compare only date (ignoring time)
      final createdDateOnly = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );

      // Only deactivate missions created before today
      if (createdDateOnly.isBefore(today)) {
        await doc.reference.update({'status': false});
        expiredMissionIds.add(doc.id);
        updatedCount++;
      }
    }

    print("✅ Expired ${updatedCount} missions created before today.");
    if (expiredMissionIds.isNotEmpty) {
      print("🗂️ Updated mission IDs: ${expiredMissionIds.join(', ')}");
    }
  }

  Future<List<MissionModel>> fetchStatusTrueMissions(String userId) async {
    // Get today's date (just the date part, no time)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Create Timestamp objects for today's start and end
    final todayStart = Timestamp.fromDate(today);
    final todayEnd = Timestamp.fromDate(tomorrow);
    
    final querySnapshot = await missionsRef
        .where('assignedUser', isEqualTo: userId)
        .where('status', isEqualTo: true)
        .where('finished', isEqualTo: false)
        .where('createdAt', isGreaterThanOrEqualTo: todayStart)
        .where('createdAt', isLessThan: todayEnd)
        .get();
        
    final missions = querySnapshot.docs
        .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
        .toList();
    
    print("Found ${missions.length} active missions for today for user: $userId");
    return missions;
  }

  Future<List<MissionModel>> fetchFinishedMissions(String userId) async {
    final querySnapshot =
        await missionsRef
            .where('assignedUser', isEqualTo: userId)
            .where('finished', isEqualTo: true)
            .get();
    return querySnapshot.docs
        .map((doc) => MissionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Main function to generate missions, store in Firebase, and update app state.
  Future<void> generateAndStoreMissions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("No user is logged in.");
      
      // First check if user already has active missions for today
      final activeMissions = await fetchStatusTrueMissions(currentUser.uid);
      
      // If user already has active missions, don't generate new ones
      if (activeMissions.isNotEmpty) {
        print("✅ User already has ${activeMissions.length} active missions. Skipping generation.");
        return;
      }
      
      // Check if we need to generate missions today (based on date)
      bool shouldGenerate = await isDateAfterCreated();
      if (!shouldGenerate) {
        print("❌ No need to generate missions today based on date check.");
        return;
      }

      // Deactivate old missions before generating new ones
      await clearMissionList();
      
      // Generate new missions
      final geminiService = GeminiModerationService();
      final geminiJson = await geminiService.generateMissionJsonFromPrompt();

      final parsed = json.decode(geminiJson);
      if (parsed['missions'] == null || parsed['missions'] is! List) {
        throw Exception('No missions found in the Gemini response or invalid format');
      }

      final assignedUserId = currentUser.uid;

      // Build list of MissionModel with added fields
      final missions = (parsed['missions'] as List).map((e) {
        e['status'] = true;
        e['assignedUser'] = assignedUserId;
        e['progress'] = 0;
        return MissionModel.fromMap(e, e['id']);
      }).toList();

      await saveGeneratedMissionsToFirebase(missions);
      print("✅ Generated ${missions.length} new missions for user: $assignedUserId");
    } catch (e) {
      print('❌ Error during mission generation: $e');
      rethrow;
    }
  }

  // Function to award XP to the user when the mission is finished
  Future<void> awardUserFragment(String userId, int fragment) async {
    try {
      // Get user's current level to calculate reward rate
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print("User not found when awarding fragments: $userId");
        return;
      }

      final userData = userDoc.data()!;
      final int levelValue = userData['levelValue'] ?? 1;
      
      // Calculate reward rate: 1.0 + (floor(levelValue / 10) * 0.5)
      final double rewardRate = 1.0 + ((levelValue ~/ 10) * 0.5);
      
      // Calculate effective fragment reward with the rate
      final int effectiveFragment = (fragment * rewardRate).round();
      
      // Update the user's fragmentNumber (XP) in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fragmentNumber': FieldValue.increment(
          effectiveFragment,
        ), // Add scaled XP to user's fragmentNumber
      });
      
      print("Awarded $effectiveFragment fragments (base: $fragment, rate: ${rewardRate.toStringAsFixed(2)}) to user: $userId");
    } catch (e) {
      print("Error awarding XP to the user: $e");
    }
  }

  /// Update a specific mission's progress by its ID
  Future<void> updateMissionProgress(String missionId, int progress, bool finished) async {
    try {
      await missionsRef.doc(missionId).update({
        'progress': progress,
        'finished': finished,
      });
      
      print("Updated mission ID: $missionId, progress: $progress, finished: $finished");
    } catch (e) {
      print("Error updating mission progress: $e");
      rethrow;
    }
  }
}
