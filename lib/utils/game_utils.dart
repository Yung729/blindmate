import 'dart:ui' show Offset;

class GameUtils {
  static List<Offset?> pointsFromMap(List<dynamic>? points) {
    return points?.map((pt) {
      if (pt['dx'] == null || pt['dy'] == null) return null;
      return Offset(pt['dx'], pt['dy']);
    }).toList() ?? [];
  }

  // static List<Map<String, dynamic>> pointsToMap(List<Offset?> points) {
  //   return points.map((e) {
  //     if (e == null) return {'dx': null, 'dy': null};
  //     return {'dx': e.dx, 'dy': e.dy};
  //   }).toList();
  // }

  static List<Map<String, dynamic>> pointsToMap(List<Offset?> points) {
  return points.map((e) {
    if (e == null) {
      return {'dx': null, 'dy': null}; // Handling null Offset
    }
    return {'dx': e.dx, 'dy': e.dy}; // Handling non-null Offset
  }).toList();
}

  static String getRandomWord() {
    final words = ["Sunflower", "Rocket", "Pizza", "Tree"];
    words.shuffle();
    return words.first;
  }
} 