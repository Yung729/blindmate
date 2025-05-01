import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/viewmodels/dataBinding/auth_data_binding.dart';
import 'package:blindmate/viewmodels/dataBinding/survey_dialog_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/auth_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/viewmodels/state/survey_dialog_state.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/views/screens/survey.dart';

class SurveyDialogEventHandler {
  final SurveyDialogState _surveyDialogState;
  final SurveyDialogDataBinding _dataBinding;
  final AuthState _authState;

  SurveyDialogEventHandler({
    required SurveyDialogState surveyDialogState,
    required SurveyDialogDataBinding dataBinding,
    required AuthState authState,
  }) : _surveyDialogState = surveyDialogState,
       _dataBinding = dataBinding,
       _authState = authState;

  Future<void> init(BuildContext context) async {
    if (!_surveyDialogState.hasShownSurveyDialog && _authState.currentUser != null) {
      bool shouldShowDialog = await _dataBinding.shouldShowSurveyDialog(_authState.currentUser!.userId);
      if (shouldShowDialog) {
        showSurveyDialog(context);
      }
    }
  }


  void goToSurvey(BuildContext context) {
    final UserModel? user = _authState.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SurveyPage(userId: user.userId),
        ),
      ).then((_) async {
        // Refresh user data after survey
        final eventHandler = AuthEventHandler(_authState, AuthDataBinding());
        await eventHandler.fetchUserData(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  void showSurveyDialog(BuildContext context) {
    final UserModel? user = _authState.currentUser;
    if (user != null) {
      _dataBinding.updatePopDialogTimestamp(user.userId);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Survey Invitation'),
          content: const Text(
            'Would you like to answer survey question?\nNote: It may increase your level.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                goToSurvey(context);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    }
  }
}