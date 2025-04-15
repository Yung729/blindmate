import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class LevelProgressionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserLevel(
    String userId,
    int totalScore,
    int numberOfQuestions,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }

      final data = userDoc.data() as Map<String, dynamic>;

      int levelValue = (data['levelValue'] as int? ?? 1).clamp(1, 9999);
      double progressionValue = (data['progressionValue'] as num? ?? 0.0)
          .toDouble()
          .clamp(0.0, 1.0);

      // Fetch and aggregate safeCount, warningCount, and unsafeCount from relevant summaries
      int totalSafeCount = 0;
      int totalWarningCount = 0;
      int totalUnsafeCount = 0;

      // Define the target date (13 April 2025), ignoring time by covering the entire day
      final targetDateStart = DateTime(
        2025,
        4,
        13,
        0,
        0,
        0,
      ); // Start of 13 April 2025 (00:00:00)
      final targetDateEnd = DateTime(
        2025,
        4,
        14,
        0,
        0,
        0,
      ); // Start of 14 April 2025 (00:00:00, exclusive)

      // Convert target dates to Firestore Timestamps
      final targetDateStartTimestamp = Timestamp.fromDate(targetDateStart);
      final targetDateEndTimestamp = Timestamp.fromDate(targetDateEnd);

      print('Filtering chats for date 13 April 2025 (ignoring time)');
      print('Range: $targetDateStart to $targetDateEnd');

      // Query chats collection, filtering by createdAt to match only the date 13 April 2025
      QuerySnapshot<Map<String, dynamic>> summariesSnapshot = await _firestore
          .collectionGroup('summaries')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: targetDateStartTimestamp)
          .where('timestamp', isLessThan: targetDateEndTimestamp)
          .get();

      print('Found ${summariesSnapshot.docs.length} summaries for user $userId on 13 April 2025');

      for (var summaryDoc in summariesSnapshot.docs) {
        var summaryData = summaryDoc.data();
        totalSafeCount += summaryData['safeCount'] as int? ?? 0;
        totalWarningCount += summaryData['warningCount'] as int? ?? 0;
        totalUnsafeCount += summaryData['unsafeCount'] as int? ?? 0;
      }

      // Log the counts to the terminal
      print('Chat Behavior Counts (13 April 2025):');
      print('Total Safe Count: $totalSafeCount');
      print('Total Warning Count: $totalWarningCount');
      print('Total Unsafe Count: $totalUnsafeCount');

      // Calculate chatScore
      double chatScore = 0.0;
      int totalCounts = totalSafeCount + totalWarningCount + totalUnsafeCount;
      if (totalCounts > 0) {
        chatScore =
            ((totalSafeCount * 1) -
                (totalWarningCount * 0) -
                (totalUnsafeCount * (-1))) /
            totalCounts;
      } else {
        chatScore = 1.0; // Default to 1.0 if there are no counts
      }
      chatScore = chatScore.clamp(0.5, 1.5);

      // Calculate surveyScore
      double surveyScore =
          numberOfQuestions > 0 ? totalScore / numberOfQuestions : 0.0;

      // Calculate the difference between chatScore and surveyScore
      double scoreDifference = (chatScore - surveyScore).abs();

      // Level up logic
      const double baseIncrement = 0.1;

      if (totalScore > 0) {
        double increment = totalScore * baseIncrement;

        // Adjust increment using chatScore
        increment *= chatScore;

        // Apply difficulty factor based on level
        double difficultyFactor = 1 / (1 + log(levelValue));
        increment *= difficultyFactor;

        // If the difference between chatScore and surveyScore is less than 0.3, increase progressionValue
        if (scoreDifference < 0.3) {
          progressionValue += 0.05; // Small boost to progressionValue
          progressionValue = progressionValue.clamp(0.0, 1.0);
          print(
            'Score difference ($scoreDifference) < 0.3, increasing progressionValue by 0.05',
          );
        }

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

      print(
        'Updated $userId → levelValue: $levelValue | progressionValue: ${progressionValue.toStringAsFixed(2)}',
      );
      print(
        'chatScore: ${chatScore.toStringAsFixed(2)} | surveyScore: ${surveyScore.toStringAsFixed(2)} | scoreDifference: ${scoreDifference.toStringAsFixed(2)}',
      );
    } catch (e) {
      print('Error in updateUserLevel: $e');
      rethrow;
    }
  }
}
