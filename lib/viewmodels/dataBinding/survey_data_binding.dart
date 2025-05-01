import 'package:flutter/material.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:blindmate/services/level_progression_service.dart';
import 'package:blindmate/models/dataModels/survey_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyDataBinding extends ChangeNotifier {
  final GeminiModerationService _surveyService = GeminiModerationService();
  final LevelProgressionService _levelService = LevelProgressionService();
  SurveyModel _surveyModel = SurveyModel.empty(); 
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  SurveyModel get surveyModel => _surveyModel;

  set surveyModel(SurveyModel newModel) {
    _surveyModel = newModel;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  SurveyDataBinding() {
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _surveyModel = SurveyModel.empty();
    notifyListeners();

    try {
      final response = await _surveyService.generateSurveyQuestions();
      _surveyModel = SurveyModel.fromJson(response);
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Error fetching survey questions: $e';
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitSurvey({
    required String userId,
    required int totalScore,
    required int numberOfQuestions,
  }) async {
    try {
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
      };
    } catch (e) {
      return {'success': false, 'message': 'Error updating level: $e'};
    }
  }
}