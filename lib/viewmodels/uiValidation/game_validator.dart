import 'dart:ui' show Offset;

class GameValidator {
  static bool isValidGuess(String guess) {
    return guess.trim().isNotEmpty;
  }

  static bool isValidPoint(Offset point, double canvasWidth, double canvasHeight) {
    return point.dx >= 0 && point.dy >= 0 && point.dx <= canvasWidth && point.dy <= canvasHeight;
  }
  
}   