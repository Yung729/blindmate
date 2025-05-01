import 'package:flutter/material.dart';

class SurveyDialogState extends ChangeNotifier {
  bool _hasShownSurveyDialog = false;

  bool get hasShownSurveyDialog => _hasShownSurveyDialog;

  void setHasShownSurveyDialog(bool shown) {
    _hasShownSurveyDialog = shown;
    notifyListeners();
  }

  void clear() {
    _hasShownSurveyDialog = false;
    notifyListeners();
  }
}