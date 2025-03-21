import 'dart:convert';
import 'package:http/http.dart' as http;

class GiphyService {
  final String apiKey = "jVgA54MPsy53gLLoYAcPvoqIKLl7vuCc"; // ✅ Replace with your Giphy API Key

  Future<List<String>> fetchStickers(String query) async {
    final url = Uri.parse(
      "https://api.giphy.com/v1/stickers/search?api_key=$apiKey&q=$query&limit=10&rating=g",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<String> stickers = (data['data'] as List)
          .map((item) => item['images']['original']['url'].toString())
          .toList();

      return stickers;
    } else {
      return [];
    }
  }
}
