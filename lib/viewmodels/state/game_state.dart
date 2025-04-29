import 'package:flutter/material.dart';
import 'dart:ui' show Offset;

class GameState extends ChangeNotifier {
  List<Offset?> _points = [];
  bool _isDrawer = false;
  bool _guessCorrect = false;
  bool _isInitialized = false;
  bool _winnerDialogShown = false;
  bool _isGameEnded = false;
  int _remainingAttempts = 2;
  bool _isInactiveWarningShown = false;
  bool _isGameOver = false;
  String _currentWord = '';
  Map<String, int> _scores = {};
  String? _winner;

  List<Offset?> get points => _points;
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

  void setPoints(List<Offset?> points) {
    _points = points;
    notifyListeners();
  }

  void addPoint(Offset point) {
    _points.add(point);
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

  void reset() {
    _points.clear();
    _isDrawer = false;
    _guessCorrect = false;
    _isInitialized = false;
    _winnerDialogShown = false;
    _isGameEnded = false;
    _remainingAttempts = 2;
    _isInactiveWarningShown = false;
    _isGameOver = false;
    _currentWord = '';
    _scores = {};
    _winner = null;
    notifyListeners();
  }
} 