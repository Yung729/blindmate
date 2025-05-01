// File: survey_screen.txt
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blindmate/viewmodels/dataBinding/survey_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/survey_event_handler.dart';
import 'package:blindmate/viewmodels/state/survey_state.dart';

class SurveyPage extends StatefulWidget {
  final String userId;

  const SurveyPage({super.key, required this.userId});

  static const IconData question_circle_fill = IconData(
    0xf790,
    fontFamily: 'CupertinoIcons',
    fontPackage: 'cupertino_icons',
  );

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  void _showSurveyGuidanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                Navigator.pop(context);
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SurveyState()),
        Provider<SurveyDataBinding>(
          create: (context) => SurveyDataBinding(
            surveyState: Provider.of<SurveyState>(context, listen: false),
          ),
        ),
        Provider<SurveyEventHandler>(
          create: (context) => SurveyEventHandler(
            dataBinding: Provider.of<SurveyDataBinding>(context, listen: false),
            surveyState: Provider.of<SurveyState>(context, listen: false),
          ),
        ),
      ],
      child: Consumer<SurveyState>(
        builder: (context, surveyState, _) {
          final eventHandler = Provider.of<SurveyEventHandler>(context, listen: false);
          final surveyModel = surveyState.surveyModel;

          return Theme(
            data: Theme.of(context).copyWith(
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.blue;
                  }
                  return Colors.grey[400];
                }),
                overlayColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.1)),
              ),
            ),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Weekly Mental Health Survey'),
                actions: [
                  IconButton(
                    icon: const Icon(
                      SurveyPage.question_circle_fill,
                      color: Colors.black,
                      size: 24,
                    ),
                    onPressed: () => _showSurveyGuidanceDialog(context),
                    tooltip: 'Survey Guidance',
                  ),
                ],
              ),
              body: surveyState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : surveyState.hasError || surveyModel.questions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                surveyState.hasError
                                    ? 'Failed to load survey question: ${surveyState.errorMessage}'
                                    : 'No question generated.',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: eventHandler.fetchQuestions,
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
                                ...surveyModel.questions.asMap().entries.map((entry) {
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
                                            color: surveyModel.selectedOptions[questionId] == option.text
                                                ? Colors.blue.withOpacity(0.1)
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: RadioListTile<String>(
                                            value: option.text,
                                            groupValue: surveyModel.selectedOptions[questionId],
                                            onChanged: surveyState.isSubmitting
                                                ? null
                                                : (value) {
                                                    eventHandler.onOptionSelected(
                                                      questionId,
                                                      value!,
                                                      option.score,
                                                    );
                                                  },
                                            title: Text(
                                              option.text,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: surveyModel.selectedOptions[questionId] == option.text
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: surveyModel.selectedOptions[questionId] == option.text
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
                                    onPressed: surveyState.isSubmitting || !eventHandler.areAllQuestionsAnswered()
                                        ? null
                                        : () async {
                                            final result = await eventHandler.onSubmitSurvey(widget.userId);
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
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: eventHandler.areAllQuestionsAnswered() && !surveyState.isSubmitting
                                          ? Colors.blue
                                          : Colors.grey[400],
                                    ),
                                    child: surveyState.isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
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