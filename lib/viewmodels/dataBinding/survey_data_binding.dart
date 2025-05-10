import 'dart:async';
import 'package:blindmate/models/api/gemini_moderation_service.dart';
import 'package:blindmate/services/level_progression_service.dart';
import 'package:blindmate/models/dataModels/survey_model.dart';
import 'package:blindmate/viewmodels/state/survey_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyDataBinding {
  final GeminiModerationService _surveyService = GeminiModerationService();
  final LevelProgressionService _levelService = LevelProgressionService();
  final SurveyState _surveyState;

  SurveyDataBinding({required SurveyState surveyState}) : _surveyState = surveyState {
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    print('🔍 SurveyDataBinding: Starting fetchQuestions');
    Future.microtask(() {
      _surveyState.clear();
      _surveyState.setLoading(true);
      _surveyState.setError(null);
      _surveyState.setSurveyModel(SurveyModel.empty());
    });

    try {
      final response = await _surveyService.generateSurveyQuestions().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏳ SurveyDataBinding: generateSurveyQuestions timed out after 10 seconds');
          throw TimeoutException('Failed to fetch survey questions: Request timed out');
        },
      );
      print('✅ SurveyDataBinding: Successfully fetched questions: $response');
      final surveyModel = SurveyModel.fromJson(response);
      _surveyState.setSurveyModel(surveyModel);
    } catch (e, stackTrace) {
      print('❌ SurveyDataBinding: Error fetching survey questions: $e');
      print('Stack trace: $stackTrace');
      _surveyState.setError('Error fetching survey questions: $e');
    } finally {
      print('🏁 SurveyDataBinding: fetchQuestions completed, setting isLoading to false');
      _surveyState.setLoading(false);
    }
  }

  void updateOptionSelection(String questionId, String optionText, int score) {
    final surveyModel = _surveyState.surveyModel;
    final updatedSelectedOptions = Map<String, String?>.from(surveyModel.selectedOptions)
      ..[questionId] = optionText;
    final updatedOptionScores = Map<String, int>.from(surveyModel.optionScores)
      ..[questionId] = score;

    _surveyState.setSurveyModel(surveyModel.copyWith(
      selectedOptions: updatedSelectedOptions,
      optionScores: updatedOptionScores,
    ));
  }

  Future<Map<String, dynamic>> submitSurvey({
    required String userId,
    required int totalScore,
    required int numberOfQuestions,
  }) async {
    try {
      _surveyState.setSubmitting(true);

      // Fetch current level and last celebrated milestone before updating
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }
      final data = userDoc.data() as Map<String, dynamic>;
      final int lastCelebratedMilestone = data['lastCelebratedMilestone'] as int? ?? 0;

      String message;
      if (totalScore >= numberOfQuestions) {
        message = 'You seem to be doing great! Keep it up!';
      } else if (totalScore > 0) {
        message = 'You’re doing okay, but consider checking in with yourself.';
      } else {
        message = 'It looks like you might need support. Consider reaching out.';
      }

      final scores = await _levelService.updateUserLevel(
        userId,
        totalScore,
        numberOfQuestions,
      );

      // Fetch new level after updating
      final updatedUserDoc = await userRef.get();
      final updatedData = updatedUserDoc.data() as Map<String, dynamic>;
      final int newLevel = (updatedData['levelValue'] as int? ?? 1).clamp(1, 9999);

      // Check if the new level is a milestone and hasn't been celebrated
      if (newLevel % 10 == 0 && newLevel > lastCelebratedMilestone) {
        _surveyState.setShowLevelMilestoneFeedback(true); // Update via SurveyState
        // Update Firestore with the new celebrated milestone
        await userRef.update({
          'lastCelebratedMilestone': newLevel,
        });
      } else {
        _surveyState.setShowLevelMilestoneFeedback(false); // Update via SurveyState
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'surveyDate': Timestamp.fromDate(DateTime.now()),
      });

      String scoreComparisonMessage;
      if (scores['scoreDifference']! < 0.3) {
        scoreComparisonMessage =
            'Both chat score and survey score are close. Your level will be increased.';
      } else {
        scoreComparisonMessage =
            'Both chat score and survey score are differed too much. Your level will be remained.';
      }

      return {
        'success': true,
        'totalScore': totalScore,
        'message': message,
        'scoreComparisonMessage': scoreComparisonMessage,
        'scores': scores,
        'newLevel': newLevel,
      };
    } catch (e) {
      _surveyState.setError('Error updating level: $e');
      return {'success': false, 'message': 'Error updating level: $e'};
    } finally {
      _surveyState.setSubmitting(false);
    }
  }
}