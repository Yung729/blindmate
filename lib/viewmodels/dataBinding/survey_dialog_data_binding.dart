import 'package:blindmate/services/survey_service.dart';
import 'package:blindmate/viewmodels/state/survey_dialog_state.dart';

class SurveyDialogDataBinding {
  final SurveyService _surveyService = SurveyService();
  final SurveyDialogState _surveyDialogState;

  SurveyDialogDataBinding({required SurveyDialogState surveyDialogState})
      : _surveyDialogState = surveyDialogState;

  Future<bool> shouldShowSurveyDialog(String userId) async {
    bool shouldShow = await _surveyService.shouldShowSurveyDialog(userId);
    if (shouldShow) {
      _surveyDialogState.setHasShownSurveyDialog(true);
    }
    return shouldShow;
  }

  Future<void> updatePopDialogTimestamp(String userId) async {
    await _surveyService.updatePopDialogTimestamp(userId);
  }
}