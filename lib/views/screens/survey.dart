import 'package:flutter/material.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:blindmate/models/dataModels/survey_question_model.dart';
import 'package:blindmate/services/level_progression_service.dart'; // Import LevelProgressionService
import 'dart:convert';

class SurveyPage extends StatefulWidget {
  final String userId; // Add userId to identify the user

  const SurveyPage({super.key, required this.userId});

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final GeminiModerationService _surveyService = GeminiModerationService();
  final LevelProgressionService _levelService = LevelProgressionService(); // Initialize LevelProgressionService
  List<SurveyQuestion> _questions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, String?> _selectedOptions = {};
  Map<String, int> _optionScores = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _questions = [];
      _selectedOptions = {};
      _optionScores = {};
    });

    try {
      final dynamic response = await _surveyService.generateSurveyQuestions();

      print('\n🔍 Type of response after Gemini call: ${response.runtimeType}');

      if (response is List) {
        print('\n✅ Response is a List. Length: ${response.length}');
        print('\n✨ Raw JSON Response (from SurveyPage):\n');
        JsonEncoder encoder = const JsonEncoder.withIndent('  ');
        print(encoder.convert(response));

        try {
          List<SurveyQuestion> surveyQuestions = (response as List<dynamic>)
              .map((json) => SurveyQuestion.fromJson(json))
              .toList();

          print('\n✅ Successfully parsed SurveyQuestion list. Length: ${surveyQuestions.length}');
          print('\n✅ Parsed Survey Questions:\n');
          for (var question in surveyQuestions) {
            print('ID: ${question.id}');
            print('Question: ${question.question}');
            for (var option in question.options) {
              print('- Text: ${option.text}, Level: ${option.level}, Score: ${option.score}');
            }
            print('---');
          }

          setState(() {
            _questions = surveyQuestions;
            _isLoading = false;
            for (var question in _questions) {
              _selectedOptions[question.id.toString()] = null;
              _optionScores[question.id.toString()] = 0;
            }
          });
        } catch (e) {
          print('\n❌ Error during SurveyQuestion parsing: $e');
          if (response is List) {
            print('\n⚠️ Raw List content that caused error:');
            print(response);
          }
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Error parsing survey questions: $e';
          });
        }
      } else {
        print('\n❌ Error: Gemini response was not a List.');
        print(response);
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Unexpected response format: Not a list';
        });
      }
    } catch (e) {
      print('\n❌ Error during Gemini service call: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  bool _areAllQuestionsAnswered() {
    return _selectedOptions.values.every((option) => option != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Mental Health Survey')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError || _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _hasError
                            ? 'Failed to load survey question: $_errorMessage'
                            : 'No question generated.',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchQuestions,
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        ..._questions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final question = entry.value;
                          final questionId = question.id.toString();
                          final options = question.options;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${index + 1}. ${question.question}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...options.map((option) {
                                final optionText = option.text;
                                final score = option.score;

                                return RadioListTile<String>(
                                  title: Text(optionText),
                                  value: optionText,
                                  groupValue: _selectedOptions[questionId],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedOptions[questionId] = value;
                                      _optionScores[questionId] = score;
                                    });
                                  },
                                );
                              }).toList(),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _areAllQuestionsAnswered()
                                ? () async {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      _formKey.currentState?.save();
                                      final totalScore = _optionScores.values.reduce((a, b) => a + b);
                                      String message;
                                      if (totalScore >= _questions.length) {
                                        message = 'You seem to be doing great! Keep it up!';
                                      } else if (totalScore > 0) {
                                        message = 'You’re doing okay, but consider checking in with yourself.';
                                      } else {
                                        message = 'It looks like you might need support. Consider reaching out.';
                                      }

                                      // Update user level using LevelProgressionService
                                      try {
                                        await _levelService.updateUserLevel(widget.userId, totalScore);
                                        
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error updating level: $e')),
                                          );
                                        }
                                      }

                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Thank you!'),
                                          content: Text(
                                            'Survey submitted successfully.\nScore: $totalScore\n$message',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please answer the question before submitting.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}