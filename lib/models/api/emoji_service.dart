import 'dart:convert';
import 'package:http/http.dart' as http;

class EmojiService {
  final String _apiKey = "0aa9967b3d5c9353093c503ce440d2c589f1f757"; // Replace with your API key
  final String _apiUrl = "https://emoji-api.com/emojis";

  Future<List<String>> fetchEmojis() async {
    final response = await http.get(Uri.parse("$_apiUrl?access_key=$_apiKey"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((emoji) => emoji['character'] as String).toList();
    } else {
      throw Exception("Failed to load emojis");
    }
  }
}
