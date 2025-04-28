// import 'dart:convert';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiModerationService {
  final String apiKey = 'AIzaSyCpduqdv3nfhxOZ4bF99Mm2YEuYc3OLAgs';

  Future<String?> checkContentLevel(String message) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
Act as a content moderator. Analyze the following message and respond with ONLY ONE of the following labels:

- "SAFE": if the message is appropriate for all users.
- "WARNING": if it contains mild sensitive content or may be inappropriate for younger users.
- "UNSAFE": if it contains hate speech, explicit, violent, or offensive material.

Message:
"$message"
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final result = response.text?.trim().toUpperCase();

    if (result == 'SAFE' || result == 'WARNING' || result == 'UNSAFE') {
      print('Moderation result: $result');
      return result;
    }

    // Fallback if AI doesn't give expected format
    return 'UNSAFE';
  }

  Future<bool> isStickerSearchPositive(String query) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
Evaluate the following sticker search query and determine if it will likely return positive or negative stickers.
Respond with ONLY ONE of the following labels:

- "POSITIVE": if the query will likely return positive, uplifting, happy, friendly, or neutral stickers.
- "NEGATIVE": if the query will likely return negative, offensive, violent, explicit, or inappropriate stickers.

For example:
- "happy", "love", "cute", "smile", "information", "weather" would be POSITIVE
- "hate", "violence", "explicit", "offensive" would be NEGATIVE

Query:
"$query"
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim().toUpperCase();

      print('Sticker query moderation result: $result');
      return result == 'POSITIVE';
    } catch (e) {
      print('Error moderating sticker query: $e');
      return false; // Default to not allowing if there's an error
    }
  }

Future<List<Map<String, dynamic>>> generateSurveyQuestions() async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
    I'm building a mental health app.
    Please generate 5 simple weekly self-assessment questions to help users reflect on their mental well-being. Do not repeat the same questions everytime I request.

    For each question:
    • Provide 3 multiple choice answers.
    • Map each answer to a level: Safe, Warning, or Unsafe.
    • Also include a score: Safe = 1, Warning = 0, Unsafe = -1.

    Return the result in JSON format with the following structure:
    • id: a unique ID in int for the question eg. 1,2,3,4,5
    • question: the question text
    • options: an array of answers, each with:
    • text: the option text
    • level: "Safe", "Warning", or "Unsafe"
    • score: 1, 0, or -1
    ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);

      print('\n📝 Raw response:');
      print(response.text);

      final cleanedJson =
          response.text
              ?.replaceAll(
                RegExp(r'```json|```'),
                '',
              ) // Remove code block markers
              .trim();

      if (cleanedJson == null || cleanedJson.isEmpty) {
        print('\n⚠️ Warning: Received an empty response from Gemini.');
        return [];
      }

      final List<dynamic> questions = json.decode(cleanedJson);
      return questions.cast<Map<String, dynamic>>();

    } catch (e) {
      print('Error generating survey: $e');
      rethrow;
    }
  }
}
