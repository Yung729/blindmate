import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/survey_model.dart';
import 'package:blindmate/viewmodels/dataBinding/survey_data_binding.dart';

class SurveyEventHandler extends ChangeNotifier {
  SurveyDataBinding _dataBinding;

  SurveyEventHandler(this._dataBinding);

  SurveyModel get surveyModel => _dataBinding.surveyModel;

  bool areAllQuestionsAnswered() {
    return surveyModel.selectedOptions.values.every((option) => option != null);
  }

  int calculateTotalScore() {
    return surveyModel.optionScores.values.reduce((a, b) => a + b);
  }

  void onOptionSelected(String questionId, String optionText, int score) {
    final updatedSelectedOptions = Map<String, String?>.from(surveyModel.selectedOptions)
      ..[questionId] = optionText;
    final updatedOptionScores = Map<String, int>.from(surveyModel.optionScores)
      ..[questionId] = score;

    _dataBinding.surveyModel = surveyModel.copyWith(
      selectedOptions: updatedSelectedOptions,
      optionScores: updatedOptionScores,
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> onSubmitSurvey(String userId) async {
    if (!areAllQuestionsAnswered()) {
      return {'success': false, 'message': 'Please answer all questions'};
    }

    final totalScore = calculateTotalScore();
    final numberOfQuestions = surveyModel.questions.length;

    return await _dataBinding.submitSurvey(
      userId: userId,
      totalScore: totalScore,
      numberOfQuestions: numberOfQuestions,
    );
  }
}