import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blindmate/models/dataModels/survey_model.dart';

class SurveyPage extends StatelessWidget {
  final String userId;

  const SurveyPage({super.key, required this.userId});

  static const IconData question_circle_fill = IconData(
    0xf790,
    fontFamily: 'CupertinoIcons',
    fontPackage: 'cupertino_icons',
  );

  void _showSurveyGuidanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Survey Form Guidance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Each question is scored with -1, 0, or 1 mark.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The final survey score is calculated by dividing the total score gained by the number of questions.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This score is then compared with the chat score you earn while chatting with others.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If the score difference is small (not more than 0.3), your level will increase.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'As your level increases, it will become more difficult to increase further.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the guidance dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Got It',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SurveyModel()..fetchQuestions(),
      child: Consumer<SurveyModel>(
        builder: (context, model, child) {
          return Theme(
            // Customize Radio button theme
            data: Theme.of(context).copyWith(
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.blue; // Selected radio button color
                  }
                  return Colors.grey[400]; // Unselected radio button color
                }),
                overlayColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.1)), // Ripple effect
              ),
            ),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Weekly Mental Health Survey'),
                actions: [
                  IconButton(
                    icon: const Icon(
                      question_circle_fill,
                      color: Colors.black,
                      size: 24,
                    ),
                    onPressed: () => _showSurveyGuidanceDialog(context),
                    tooltip: 'Survey Guidance',
                  ),
                ],
              ),
              body: model.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : model.hasError || model.questions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                model.hasError
                                    ? 'Failed to load survey question: ${model.errorMessage}'
                                    : 'No question generated.',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: model.fetchQuestions,
                                child: const Text('Retry'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: GlobalKey<FormState>(),
                            child: ListView(
                              children: [
                                ...model.questions.asMap().entries.map((entry) {
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
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          decoration: BoxDecoration(
                                            color: model.selectedOptions[questionId] == option.text
                                                ? Colors.blue.withOpacity(0.1) // Selected background
                                                : Colors.grey[100], // Unselected background
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: RadioListTile<String>(
                                            value: option.text,
                                            groupValue: model.selectedOptions[questionId],
                                            onChanged: (value) {
                                              model.selectOption(questionId, value!, option.score);
                                            },
                                            title: Text(
                                              option.text,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: model.selectedOptions[questionId] == option.text
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: model.selectedOptions[questionId] == option.text
                                                    ? Colors.blue
                                                    : Colors.black,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
                                            dense: true,
                                            activeColor: Colors.blue,
                                            toggleable: false,
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: model.areAllQuestionsAnswered()
                                        ? () async {
                                            final result = await model.submitSurvey(userId);
                                            if (result['success'] == true) {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Thank you!'),
                                                  content: Text(
                                                    'Survey submitted successfully.\n'
                                                    'Score: ${result['totalScore']}\n'
                                                    '${result['message']}\n\n'
                                                    '${result['scoreComparisonMessage']}\n\n'
                                                    'Chat Score: ${result['scores']['chatScore']!.toStringAsFixed(2)}\n'
                                                    'Survey Score: ${result['scores']['surveyScore']!.toStringAsFixed(2)}\n'
                                                    'Score Difference: ${result['scores']['scoreDifference']!.toStringAsFixed(2)}',
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
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(result['message'])),
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
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: model.areAllQuestionsAnswered()
                                          ? Colors.blue
                                          : Colors.grey[400],
                                    ),
                                    child: const Text(
                                      'Submit',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          );
        },
      ),
    );
  }
}