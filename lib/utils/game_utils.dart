import 'dart:ui' show Offset;

class GameUtils {
  // This method is kept for backward compatibility but is no longer used
  static List<Offset?> pointsFromMap(List<dynamic>? points) {
    return points?.map((pt) {
      if (pt == null || pt['dx'] == null || pt['dy'] == null) return null;
      return Offset((pt['dx'] as num).toDouble(), (pt['dy'] as num).toDouble());
    }).toList() ?? [];
  }

  // Convert a list of colored points to a list of maps
  static List<Map<String, dynamic>?> coloredPointsToMap(List<Map<String, dynamic>?> points) {
    return points.map((point) {
      if (point == null) return null;
      return point;
    }).toList();
  }

  // Convert a list of maps to a list of colored points
  static List<Map<String, dynamic>?> coloredPointsFromMap(List<dynamic>? points) {
    return points?.map((pt) {
      if (pt == null) return null;
      return pt as Map<String, dynamic>;
    }).toList() ?? [];
  }

  static String getRandomWord() {
    final words = ["Sunflower", "Rocket", "Pizza", "Tree"];
    words.shuffle();
    return words.first;
  }
}