import 'package:flutter/material.dart';

class GameState2 extends ChangeNotifier {
  List<String> _board = List.filled(9, '');
  bool _isPlayerX = false;
  bool _isCurrentPlayer = false;
  bool _isInitialized = false;
  bool _winnerDialogShown = false;
  String? _winner;
  Map<String, String> _roles = {};

  List<String> get board => _board;
  bool get isPlayerX => _isPlayerX;
  bool get isCurrentPlayer => _isCurrentPlayer;
  bool get isInitialized => _isInitialized;
  bool get winnerDialogShown => _winnerDialogShown;
  String? get winner => _winner;
  Map<String, String> get roles => _roles;

  void setBoard(List<String> board) {
    _board = board;
    notifyListeners();
  }

  void setCell(int index, String value) {
    _board[index] = value;
    notifyListeners();
  }

  void setIsPlayerX(bool isPlayerX) {
    _isPlayerX = isPlayerX;
    notifyListeners();
  }

  void setIsCurrentPlayer(bool isCurrentPlayer) {
    _isCurrentPlayer = isCurrentPlayer;
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

  void setWinner(String? winner) {
    _winner = winner;
    notifyListeners();
  }

  void setRoles(Map<String, String> roles) {
    _roles = roles;
    notifyListeners();
  }

  void reset() {
    _board = List.filled(9, '');
    _isPlayerX = false;
    _isCurrentPlayer = false;
    _isInitialized = false;
    _winnerDialogShown = false;
    _winner = null;
    _roles = {};
    notifyListeners();
  }
} 