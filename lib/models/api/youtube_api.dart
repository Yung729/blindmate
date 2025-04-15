// lib/services/youtube_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeAPI {
  static const String youtubeApiKey = "AIzaSyDml4bzd14PlQssvJi2L6x2BMzg18IB38U";

  static Future<List<Map<String, String>>> searchYouTubeMusicList(String query) async {
    var url = Uri.parse(
      "https://www.googleapis.com/youtube/v3/search?"
      "part=snippet&q=$query&type=video&maxResults=5&key=$youtubeApiKey"
    );

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<Map<String, String>> results = [];

        for (var item in data['items']) {
          String videoId = item['id']['videoId'];
          String title = item['snippet']['title'];
          String channelTitle = item['snippet']['channelTitle'];
          
          results.add({
            'title': title,
            'artist': channelTitle,
            'url': "https://www.youtube.com/watch?v=$videoId",
          });
        }

        return results;
      } else {
        print("YouTube API Error: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
    return [];
  }
}