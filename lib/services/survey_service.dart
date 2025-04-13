import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class SurveyService {
  final String apiKey = 'AIzaSyCpduqdv3nfhxOZ4bF99Mm2YEuYc3OLAgs'; 

  Future<List<Map<String, dynamic>>> generateSurveyQuestions() async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    // Retry up to 3 times if the API fails
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final prompt = '''
      I'm building a mental health app.
      Please generate exactly 1 simple weekly self-assessment question to help users reflect on their mental well-being.
      To ensure variety, use this timestamp as a seed for randomization: $timestamp.

      For each question:
      • Provide 3 multiple choice answers.
      • Map each answer to a level: Safe, Warning, or Unsafe.
      • Also include a score: Safe = 1, Warning = 0, Unsafe = -1.

      Return the result in JSON format with the following structure:
      • id: a unique ID for the question
      • question: the question text
      • options: an array of answers, each with:
      • text: the option text
      • level: "Safe", "Warning", or "Unsafe"
      • score: 1, 0, or -1
      ''';

      try {
        print('Attempt $attempt: Sending request to Gemini API...');
        final response = await model.generateContent([Content.text(prompt)]);
        final jsonStr = response.text;
        if (jsonStr == null) {
          throw Exception('No response from Gemini API');
        }

        print('Attempt $attempt: Received response: $jsonStr');
        final List<dynamic> questions = json.decode(jsonStr);
        final result = questions.cast<Map<String, dynamic>>();
        print('Attempt $attempt: Parsed ${result.length} questions');
        return result; // Expecting exactly 1 question
      } catch (e) {
        print('Error generating survey (attempt $attempt): $e');
        if (attempt == maxRetries) {
          rethrow; // Let the caller handle the error after max retries
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Failed to generate survey questions');
  }
}