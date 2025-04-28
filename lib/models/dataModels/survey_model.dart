import 'package:flutter/material.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:blindmate/models/dataModels/survey_question_model.dart';
import 'package:blindmate/services/level_progression_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyModel extends ChangeNotifier {
  final GeminiModerationService _surveyService = GeminiModerationService();
  final LevelProgressionService _levelService = LevelProgressionService();
  List<SurveyQuestion> _questions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, String?> _selectedOptions = {};
  Map<String, int> _optionScores = {};

  List<SurveyQuestion> get questions => _questions;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  Map<String, String?> get selectedOptions => _selectedOptions;

  Future<void> fetchQuestions() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _questions = [];
    _selectedOptions = {};
    _optionScores = {};
    notifyListeners();

    try {
      final response = await _surveyService.generateSurveyQuestions();
      if (response is List) {
        _questions = response.map((json) => SurveyQuestion.fromJson(json)).toList();
        for (var question in _questions) {
          _selectedOptions[question.id.toString()] = null;
          _optionScores[question.id.toString()] = 0;
        }
        _isLoading = false;
      } else {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Unexpected response format: Not a list';
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void selectOption(String questionId, String optionText, int score) {
    _selectedOptions[questionId] = optionText;
    _optionScores[questionId] = score;
    notifyListeners();
  }

  bool areAllQuestionsAnswered() {
    return _selectedOptions.values.every((option) => option != null);
  }

  Future<Map<String, dynamic>> submitSurvey(String userId) async {
    if (!areAllQuestionsAnswered()) {
      return {'success': false, 'message': 'Please answer all questions'};
    }

    try {
      final totalScore = _optionScores.values.reduce((a, b) => a + b);
      final numberOfQuestions = _questions.length;
      String message;
      if (totalScore >= numberOfQuestions) {
        message = 'You seem to be doing great! Keep it up!';
      } else if (totalScore > 0) {
        message = 'You’re doing okay, but consider checking in with yourself.';
      } else {
        message = 'It looks like you might need support. Consider reaching out.';
      }

      // Update user level and get scores
      final scores = await _levelService.updateUserLevel(userId, totalScore, numberOfQuestions);

      // Update surveyDate in Firebase
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'surveyDate': Timestamp.fromDate(DateTime.now()),
      });

      // Determine score comparison message
      String scoreComparisonMessage;
      if (scores['scoreDifference']! < 0.3) {
        scoreComparisonMessage = 'Both chat score and survey score are close. Your level will be increased.';
      } else {
        scoreComparisonMessage = 'Both chat score and survey score are differed too much. Your level will be remained.';
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