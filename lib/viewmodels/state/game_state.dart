import 'package:flutter/material.dart';
import 'dart:ui' show Offset;
import 'dart:async';

class GameState extends ChangeNotifier {
  List<Map<String, dynamic>?> _points = []; // Changed to store both offset and color
  bool _isDrawer = false;
  bool _guessCorrect = false;
  bool _isInitialized = false;
  bool _winnerDialogShown = false;
  bool _isGameEnded = false;
  int _remainingAttempts = 3;
  bool _isInactiveWarningShown = false;
  bool _isGameOver = false;
  String _currentWord = '';
  Map<String, int> _scores = {};
  String? _winner;
  Timer? _inactivityTimer;
  Timer? _gameOverTimer;
  static const Duration _inactivityThreshold = Duration(minutes: 1);
  static const Duration _gameOverThreshold = Duration(minutes: 2);
  bool _showIncorrectGuess = false;
  Color _brushColor = Colors.blue.shade800;

  List<Map<String, dynamic>?> get points => _points;
  bool get isDrawer => _isDrawer;
  bool get guessCorrect => _guessCorrect;
  bool get isInitialized => _isInitialized;
  bool get winnerDialogShown => _winnerDialogShown;
  bool get isGameEnded => _isGameEnded;
  int get remainingAttempts => _remainingAttempts;
  bool get isInactiveWarningShown => _isInactiveWarningShown;
  bool get isGameOver => _isGameOver;
  String get currentWord => _currentWord;
  Map<String, int> get scores => _scores;
  String? get winner => _winner;
  Timer? get inactivityTimer => _inactivityTimer;
  Timer? get gameOverTimer => _gameOverTimer;
  bool get showIncorrectGuess => _showIncorrectGuess;
  Color get brushColor => _brushColor;
  
  // Helper method to get offset from point map
  Offset? getOffsetFromPoint(Map<String, dynamic>? point) {
    if (point == null) return null;
    final dx = point['dx'] as double?;
    final dy = point['dy'] as double?;
    if (dx == null || dy == null) return null;
    return Offset(dx, dy);
  }
  
  // Helper method to get color from point map
  Color getColorFromPoint(Map<String, dynamic>? point) {
    if (point == null) return Colors.blue.shade800;
    final colorValue = point['color'] as int?;
    return colorValue != null ? Color(colorValue) : Colors.blue.shade800;
  }

  void setPoints(List<Map<String, dynamic>?> points) {
    _points = points;
    notifyListeners();
  }

  void addPoint(Offset point) {
    _points.add({
      'dx': point.dx,
      'dy': point.dy,
      'color': _brushColor.value,
    });
    notifyListeners();
  }

  void addNullPoint() {
    _points.add(null);
    notifyListeners();
  }

  void clearPoints() {
    _points.clear();
    notifyListeners();
  }

  void setIsDrawer(bool isDrawer) {
    _isDrawer = isDrawer;
    notifyListeners();
  }

  void setGuessCorrect(bool correct) {
    _guessCorrect = correct;
    notifyListeners();
  }

  void setIsInitialized(bool initialized) {
    _isInitialized = initialized;
    notifyListeners();
  }

  void setWinnerDialogShown(bool shown) {
    _winnerDialogShown = shown;
    notifyListeners();
  }

  void setIsGameEnded(bool ended) {
    _isGameEnded = ended;
    notifyListeners();
  }

  void setRemainingAttempts(int attempts) {
    _remainingAttempts = attempts;
    notifyListeners();
  }

  void setIsInactiveWarningShown(bool shown) {
    _isInactiveWarningShown = shown;
    notifyListeners();
  }

  void setIsGameOver(bool over) {
    _isGameOver = over;
    notifyListeners();
  }

  void setCurrentWord(String word) {
    _currentWord = word;
    notifyListeners();
  }

  void setScores(Map<String, int> scores) {
    _scores = scores;
    notifyListeners();
  }

  void setWinner(String? winner) {
    _winner = winner;
    notifyListeners();
  }

  void incrementScore(String userId) {
    _scores[userId] = (_scores[userId] ?? 0) + 1;
    notifyListeners();
  }

  void startInactivityTimer() {
    _inactivityTimer?.cancel();
    _gameOverTimer?.cancel();
    
    _inactivityTimer = Timer(_inactivityThreshold, () {
      if (!_isInactiveWarningShown && !_isGameOver) {
        _isInactiveWarningShown = true;
        notifyListeners();
      }
    });

    _gameOverTimer = Timer(_gameOverThreshold, () {
      if (!_isGameOver) {
        _isGameOver = true;
        _isGameEnded = true;
        notifyListeners();
      }
    });
  }

  void resetInactivityTimer() {
    _isInactiveWarningShown = false;
    startInactivityTimer();
  }

  void setShowIncorrectGuess(bool show) {
    _showIncorrectGuess = show;
    notifyListeners();
  }

  void setBrushColor(Color color) {
    _brushColor = color;
    notifyListeners();
  }

  void decrementAttempts() {
    if (_remainingAttempts > 0) {
      _remainingAttempts--;
      notifyListeners();
    }
  }

  void reset() {
    _points.clear();
    _isDrawer = false;
    _guessCorrect = false;
    _isInitialized = false;
    _winnerDialogShown = false;
    _isGameEnded = false;
    _remainingAttempts = 3;
    _isInactiveWarningShown = false;
    _isGameOver = false;
    _currentWord = '';
    _scores = {};
    _winner = null;
    _showIncorrectGuess = false;
    _brushColor = Colors.blue.shade800;
    _inactivityTimer?.cancel();
    _gameOverTimer?.cancel();
    _inactivityTimer = null;
    _gameOverTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _gameOverTimer?.cancel();
    super.dispose();
  }
} 