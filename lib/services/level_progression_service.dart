import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class LevelProgressionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserLevel(String userId, int score) async {
    try {
      // Fetch the current user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }

      // Fetch the 'level' subcollection
      DocumentSnapshot levelDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('level')
          .doc('current')
          .get();

      int levelValue;
      double progressionValue;

      // Check if 'level' subcollection exists
      if (levelDoc.exists) {
        // Use the new structure
        final levelData = levelDoc.data() as Map<String, dynamic>;
        levelValue = (levelData['levelValue'] as int? ?? 1).clamp(1, 9999);
        progressionValue = (levelData['progressionValue'] as num? ?? 0.0).toDouble().clamp(0.0, 1.0);
      } else {
        // Fallback to old structure (root document) if subcollection doesn't exist
        final userData = userDoc.data() as Map<String, dynamic>;
        levelValue = (userData['mentalLevel'] as int? ?? 1).clamp(1, 9999);
        progressionValue = (userData['levelProgress'] as num? ?? 0.0).toDouble().clamp(0.0, 1.0);

        // Migrate the data to the 'level' subcollection
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('level')
            .doc('current')
            .set({
          'levelValue': levelValue,
          'progressionValue': progressionValue,
        });

        // Remove old fields from root document
        await _firestore.collection('users').doc(userId).update({
          'mentalLevel': FieldValue.delete(),
          'levelProgress': FieldValue.delete(),
        });

        print('Migrated user $userId to new level subcollection structure during update');
      }

      // Level progression logic
      const double baseIncrement = 0.1; // Base progress per positive score point
      if (score > 0) {
        // Calculate progress increment
        double progressIncrement = score * baseIncrement;

        // Apply difficulty factor: higher levels make progress slower
        double difficultyFactor = 1 / (1 + log(levelValue));
        progressIncrement *= difficultyFactor;

        // Update progressionValue
        progressionValue += progressIncrement;

        // Check for level up
        while (progressionValue >= 1.0 && levelValue < 9999) {
          levelValue += 1;
          progressionValue -= 1.0; // Carry over excess progress
        }

        // Ensure levelValue doesn't exceed 9999
        if (levelValue >= 9999) {
          levelValue = 9999;
          progressionValue = 0.0; // Cap progress at max level
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
        'progressionValue': progressionValue.clamp(0.0, 1.0),
      });

      print('Updated user: levelValue=$levelValue, progressionValue=$progressionValue');
    } catch (e) {
      print('Error updating user level: $e');
      rethrow; // Let the caller handle the error
    }
  }
}