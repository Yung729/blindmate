import 'package:blindmate/models/dataModels/survey_question_model.dart';

class SurveyModel {
  final List<SurveyQuestion> questions;
  final Map<String, String?> selectedOptions;
  final Map<String, int> optionScores;

  SurveyModel({
    required this.questions,
    required this.selectedOptions,
    required this.optionScores,
  });

  /// 🔹 Create an empty SurveyModel
  factory SurveyModel.empty() {
    return SurveyModel(
      questions: [],
      selectedOptions: {},
      optionScores: {},
    );
  }

  /// 🔹 Create SurveyModel from JSON (e.g., from GeminiModerationService)
  factory SurveyModel.fromJson(List<dynamic> json) {
    final questions = json.map((item) => SurveyQuestion.fromJson(item)).toList();
    final selectedOptions = <String, String?>{};
    final optionScores = <String, int>{};

    for (var question in questions) {
      selectedOptions[question.id.toString()] = null;
      optionScores[question.id.toString()] = 0;
    }

    return SurveyModel(
      questions: questions,
      selectedOptions: selectedOptions,
      optionScores: optionScores,
    );
  }

  /// 🔹 Create a copy with updated fields
  SurveyModel copyWith({
    List<SurveyQuestion>? questions,
    Map<String, String?>? selectedOptions,
    Map<String, int>? optionScores,
  }) {
    return SurveyModel(
      questions: questions ?? this.questions,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      optionScores: optionScores ?? this.optionScores,
    );
  }

  /// 🔹 Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((q) => {
            'id': q.id,
            'question': q.question,
            'options': q.options.map((o) => {
                  'text': o.text,
                  'level': o.level,
                  'score': o.score,
                }).toList(),
          }).toList(),
      'selectedOptions': selectedOptions,
      'optionScores': optionScores,
    };
  }
}