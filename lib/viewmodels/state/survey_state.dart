import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/survey_model.dart';

class SurveyState extends ChangeNotifier {
  SurveyModel _surveyModel = SurveyModel.empty();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _showLevelMilestoneFeedback = false; // Moved from SurveyDataBinding

  SurveyModel get surveyModel => _surveyModel;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;
  bool get showLevelMilestoneFeedback => _showLevelMilestoneFeedback; // Getter

  void setSurveyModel(SurveyModel model) {
    _surveyModel = model;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? message) {
    _hasError = message != null;
    _errorMessage = message;
    notifyListeners();
  }

  void setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  void setShowLevelMilestoneFeedback(bool show) {
    _showLevelMilestoneFeedback = show;
    notifyListeners();
  }

  void resetLevelMilestoneFeedback() {
    _showLevelMilestoneFeedback = false;
    notifyListeners();
  }

  void clear() {
    _surveyModel = SurveyModel.empty();
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _isSubmitting = false;
    _showLevelMilestoneFeedback = false; 
    notifyListeners();
  }
}