import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<List<dynamic>> searchLocations(String query) async {
    if (query.length < 3) return [];
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=8',
    );
    final response = await http.get(
      url,
      headers: {'User-Agent': 'FlutterTripJournalApp/1.0 (your@email.com)'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return [];
    }
  }
}