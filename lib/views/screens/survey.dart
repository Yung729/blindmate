import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blindmate/models/dataModels/survey_model.dart'; 

class SurveyPage extends StatelessWidget {
  final String userId;

  const SurveyPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SurveyModel()..fetchQuestions(), 
      child: Consumer<SurveyModel>( 
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('Weekly Mental Health Survey')),
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
                                      return RadioListTile<String>(
                                        title: Text(option.text),
                                        value: option.text,
                                        groupValue: model.selectedOptions[questionId],
                                        onChanged: (value) {
                                          model.selectOption(questionId, value!, option.score);
                                        },
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
                                  child: const Text('Submit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          );
        },
      ),
    );
  }
}