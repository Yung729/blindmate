import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:blindmate/models/dataModels/user_model.dart';

class LevelProgressionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserLevel(String userId, int score) async {
    try {
      // Fetch the current user data, including the 'level' subcollection
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }

      UserModel user = await UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userId);

      // Level progression logic
      const double baseIncrement = 0.1; // Base progress per positive score point
      double levelProgress = user.levelProgress;
      int levelValue = user.levelValue;

      if (score > 0) {
        // Calculate progress increment
        double progressIncrement = score * baseIncrement;

        // Apply difficulty factor: higher levels make progress slower
        double difficultyFactor = 1 / (1 + log(levelValue));
        progressIncrement *= difficultyFactor;

        // Update progressionValue
        levelProgress += progressIncrement;

        // Check for level up
        while (levelProgress >= 1.0 && levelValue < 9999) {
          levelValue += 1;
          levelProgress -= 1.0; // Carry over excess progress
        }

        // Ensure levelValue doesn't exceed 9999
        if (levelValue >= 9999) {
          levelValue = 9999;
          levelProgress = 0.0; // Cap progress at max level
        }
      }

      // Update the 'level' subcollection with new values
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('level')
          .doc('current')
          .set({
        'levelValue': levelValue,
        'progressionValue': levelProgress.clamp(0.0, 1.0),
      });

      print('Updated user: levelValue=$levelValue, progressionValue=$levelProgress');
    } catch (e) {
      print('Error updating user level: $e');
      rethrow; // Let the caller handle the error
    }
  }
}