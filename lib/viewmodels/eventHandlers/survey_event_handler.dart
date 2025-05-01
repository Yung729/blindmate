import 'package:blindmate/viewmodels/dataBinding/survey_data_binding.dart';
import 'package:blindmate/viewmodels/state/survey_state.dart';

class SurveyEventHandler {
  final SurveyDataBinding _dataBinding;
  final SurveyState _surveyState;

  SurveyEventHandler({
    required SurveyDataBinding dataBinding,
    required SurveyState surveyState,
  }) : _dataBinding = dataBinding, _surveyState = surveyState;

  bool areAllQuestionsAnswered() {
    return _surveyState.surveyModel.selectedOptions.values.every((option) => option != null);
  }

  int calculateTotalScore() {
    return _surveyState.surveyModel.optionScores.values.reduce((a, b) => a + b);
  }

  void onOptionSelected(String questionId, String optionText, int score) {
    _dataBinding.updateOptionSelection(questionId, optionText, score);
  }

  Future<Map<String, dynamic>> onSubmitSurvey(String userId) async {
    final totalScore = calculateTotalScore();
    final numberOfQuestions = _surveyState.surveyModel.questions.length;

    return await _dataBinding.submitSurvey(
      userId: userId,
      totalScore: totalScore,
      numberOfQuestions: numberOfQuestions,
    );
  }

  void fetchQuestions() {
    _dataBinding.fetchQuestions();
  }
}