// import 'dart:convert';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiModerationService {
  final String apiKey = 'AIzaSyCtfncRITsFxG7ywTaylhkZKx4E8EcEH-M';
  // new key: 'AIzaSyCtfncRITsFxG7ywTaylhkZKx4E8EcEH-M';
  // old key: 'AIzaSyCpduqdv3nfhxOZ4bF99Mm2YEuYc3OLAgs';

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

  Future<String> generateMissionJsonFromPrompt() async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final prompt = '''
  Generate 3 missions for a social app focusing ONLY on time-based OR action-based achievements.
  Each mission should use these existing tracked metrics and features:

  Time-based metrics available:
  - Chat duration (total time users spend chatting; only total time is tracked, not continuous sessions)

  Action-based metrics available:
  1. Chat Actions:
     - Number of text messages sent in chat (metric: "text")
     - Number of stickers sent in chat (metric: "sticker")
     - Number of music shared in chat (metric: "music")
     - Number of trip journals shared in chat (metric: "tripjournal")
     - Mini-games played in chat (metric: "game")

  2. Post Actions:
     - Number of text posts created (metric: "textpost")
     - Number of music posts shared (metric: "musicpost")
     - Number of trip journal posts shared (metric: "tripjournal")

  3. Bottle Note Actions:
     - Number of notes sent (metric: "note")
     - Number of notes received (metric: "receivednote")

  Return missions in this exact JSON format:
  {
    "missions": [
      {
        "id": "unique alphanumeric string id (e.g., 0fc3r0meKjngcowxbLt2)",
        "title": "Brief, engaging mission name",
        "description": "Clear, one-line description of what to accomplish. Be explicit about where the action happens (e.g., 'Share 2 music in chat' or 'Share 2 music posts'). Avoid ambiguous descriptions like 'share music'.",
        "type": "time/action",
        "category": "chat/post/note",
        "difficulty": "easy/medium/hard",
        "requirements": {
          "metric": "text/sticker/music/tripjournal/game/textpost/musicpost/note/receivednote",
          "target": number
        },
        "rewards": {
          "xp": number (100-1000)
        }
      }
    ]
  }

  Example missions:
  1. Time-based:
     - Chat for a total of 30 minutes (metric: "chat duration")

  2. Action-based:
     - Send 10 text messages in chat (metric: "text")
     - Share 3 stickers in chat (metric: "sticker")
     - Share 2 music in chat (metric: "music")
     - Create 5 music posts (metric: "musicpost")
     - Create 3 trip journal posts (metric: "tripjournal")
     - Send 3 bottle notes (metric: "note")

  IMPORTANT:
  - For action-based missions, use the EXACT metric values specified above. The metric field must match exactly one of the values in the list above.
  - Mission descriptions must clearly state the context (e.g., 'in chat', 'as a post').
  - Do NOT generate missions that require continuous actions (e.g., 'chat for 10 minutes straight'). Only total time is tracked.

  Requirements:
  - Each mission must be achievable within one session
  - Use only metrics that are actually tracked
  - Time-based missions should focus on total engagement, not continuous sessions
  - Action-based missions should encourage positive behavior
  - Rewards should match difficulty
  - Must be trackable with existing metrics

  Generate ONLY valid JSON without any additional text or explanations.
  ''';

    final response = await model.generateContent([Content.text(prompt)]);
    var jsonResult = response.text?.trim();

    print('Gemini Mission Response (Raw): $jsonResult');

    // Clean up the response
    jsonResult = jsonResult?.replaceAll(RegExp(r'^```json|\n|```'), '');

    if (jsonResult == null || jsonResult.isEmpty) {
      throw Exception('Gemini returned an empty result');
    }

    return jsonResult;
  }
}
