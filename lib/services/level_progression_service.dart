import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class LevelProgressionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 Future<void> updateUserLevel(String userId, int score) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }

      final data = userDoc.data() as Map<String, dynamic>;

      int levelValue = (data['levelValue'] as int? ?? 1).clamp(1, 9999);
      double progressionValue = (data['progressionValue'] as num? ?? 0.0).toDouble().clamp(0.0, 1.0);

      // Level up logic
      const double baseIncrement = 0.1;

      if (score > 0) {
        double increment = score * baseIncrement;
        double difficultyFactor = 1 / (1 + log(levelValue));
        increment *= difficultyFactor;

        progressionValue += increment;

        while (progressionValue >= 1.0 && levelValue < 9999) {
          levelValue += 1;
          progressionValue -= 1.0;
        }

        if (levelValue >= 9999) {
          levelValue = 9999;
          progressionValue = 0.0;
        }
      }

      // Save back to Firestore root document
      await userRef.update({
        'levelValue': levelValue,
        'progressionValue': progressionValue.clamp(0.0, 1.0),
      });

      print('Updated $userId → levelValue: $levelValue | progressionValue: ${progressionValue.toStringAsFixed(2)}');
    } catch (e) {
      print('Error in updateUserLevel: $e');
      rethrow;
    }
  }
}