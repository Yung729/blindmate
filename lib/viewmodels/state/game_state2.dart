import 'package:flutter/material.dart';
import 'dart:async';

class GameState2 extends ChangeNotifier {
  List<String> _board = List.filled(9, '');
  Map<String, String> _roles = {};
  String? _winner;
  bool _isPlayerX = false;
  bool _isCurrentPlayer = false;
  bool _isInitialized = false;
  bool _winnerDialogShown = false;
  bool _isGameEnded = false;
  bool _isInactive = false;
  bool _isInactiveWarningShown = false;
  bool _isLoading = false;
  Timer? _inactivityTimer;

  List<String> get board => _board;
  Map<String, String> get roles => _roles;
  String? get winner => _winner;
  bool get isPlayerX => _isPlayerX;
  bool get isCurrentPlayer => _isCurrentPlayer;
  bool get isInitialized => _isInitialized;
  bool get winnerDialogShown => _winnerDialogShown;
  bool get isGameEnded => _isGameEnded;
  bool get isInactive => _isInactive;
  bool get isInactiveWarningShown => _isInactiveWarningShown;
  bool get isLoading => _isLoading;

  void setIsLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setBoard(List<String> board) {
    if (!_isGameEnded) {
      _board = board;
      notifyListeners();
    }
  }

  void setCell(int index, String value) {
    if (!_isGameEnded) {
      _board[index] = value;
      notifyListeners();
    }
  }

  void setRoles(Map<String, String> roles) {
    _roles = roles;
    notifyListeners();
  }

  void setWinner(String? winner) {
    _winner = winner;
    notifyListeners();
  }

  void setIsPlayerX(bool isPlayerX) {
    _isPlayerX = isPlayerX;
    notifyListeners();
  }

  void setIsCurrentPlayer(bool isCurrentPlayer) {
    if (!_isGameEnded) {
      _isCurrentPlayer = isCurrentPlayer;
      notifyListeners();
    }
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
    if (_isGameEnded != ended) {
      _isGameEnded = ended;
      if (ended) {
        _inactivityTimer?.cancel();
      }
      notifyListeners();
    }
  }

  void setInactive(bool inactive) {
    if (_isInactive != inactive) {
      _isInactive = inactive;
      notifyListeners();
    }
  }

  void setInactiveWarningShown(bool shown) {
    if (_isInactiveWarningShown != shown) {
      _isInactiveWarningShown = shown;
      notifyListeners();
    }
  }

  void startInactivityTimer() {
    if (!_isGameEnded) {
      _inactivityTimer?.cancel();
      _inactivityTimer = Timer(const Duration(minutes: 2), () {
        if (!_isGameEnded && !_isInactive) {
          setInactive(true);
        }
      });
    }
  }

  void resetInactivityTimer() {
    if (!_isGameEnded) {
      _inactivityTimer?.cancel();
      startInactivityTimer();
    }
  }

  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void reset() {
    _board = List.filled(9, '');
    _roles = {};
    _winner = null;
    _isPlayerX = false;
    _isCurrentPlayer = false;
    _isInitialized = false;
    _winnerDialogShown = false;
    _isGameEnded = false;
    _isInactive = false;
    _isInactiveWarningShown = false;
    _inactivityTimer?.cancel();
    notifyListeners();
  }
} 
