
class SurveyOption {
  final String text;
  final String level;
  final int score;

  SurveyOption({
    required this.text,
    required this.level,
    required this.score,
  });

  factory SurveyOption.fromMap(Map<String, dynamic> map) {
    return SurveyOption(
      text: map['text'],
      level: map['level'],
      score: map['score'],
    );
  }

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      text: json['text'] as String,
      level: json['level'] as String,
      score: json['score'] as int,
    );
  }
}

class SurveyQuestion {
  final int id;
  final String question;
  final List<SurveyOption> options;

  SurveyQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  factory SurveyQuestion.fromMap(Map<String, dynamic> map) {
    return SurveyQuestion(
      id: map['id'],
      question: map['question'],
      options: (map['options'] as List)
          .map((option) => SurveyOption.fromMap(option))
          .toList(),
    );
  }

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'],
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((optionJson) => SurveyOption.fromJson(optionJson))
          .toList(),
    );
  }
}