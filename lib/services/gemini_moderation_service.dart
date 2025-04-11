import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiModerationService {
  final String apiKey = 'AIzaSyCpduqdv3nfhxOZ4bF99Mm2YEuYc3OLAgs';

  Future<String?> isContentSafe(String content) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
Act as a content moderator. Analyze the following message and say ONLY "SAFE" if it is appropriate, or 
"WARNING" if it includes sensitive content, or
"UNSAFE" if it includes hate, violence, explicit or offensive content:

"$content"
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final result = response.text?.trim().toUpperCase();

    print('Response from Gemini: $result');

    return result;
  }

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
      return result;
    }

    // fallback if AI doesn't give expected format
    return 'UNSAFE';
  }
}
