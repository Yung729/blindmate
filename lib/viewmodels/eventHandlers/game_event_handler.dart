import 'dart:async';
import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../dataBinding/game_data_binding.dart';
import '../../models/dataModels/game_model.dart';
import '../../utils/game_utils.dart';

class GameEventHandler {
  final GameState _gameState;
  final GameDataBinding _dataBinding;
  final String _chatRoomId;
  final String _currentUserId;
  final String _opponentId;
  BuildContext? _context;

  Timer? _inactivityTimer;
  Timer? _gameOverTimer;
  static const int _inactivityThreshold = 60; // 30 seconds of inactivity
  static const int _gameOverThreshold = 10; // 10 seconds after warning
  static const int _winningScore = 2;

  GameEventHandler({
    required GameState gameState,
    required GameDataBinding dataBinding,
    required String chatRoomId,
    required String currentUserId,
    required String opponentId,
  }) : _gameState = gameState,
       _dataBinding = dataBinding,
       _chatRoomId = chatRoomId,
       _currentUserId = currentUserId,
       _opponentId = opponentId;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> init(bool isDrawer) async {
    await _dataBinding.initializeGame(
      _chatRoomId,
      _currentUserId,
      _opponentId,
      isDrawer,
    );
    _dataBinding.listenToGame(_chatRoomId);
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(Duration(seconds: _inactivityThreshold), (
      timer,
    ) {
      if (!_gameState.isGameEnded && !_gameState.isInactiveWarningShown) {
        _showInactivityWarning();
      }
    });
  }

  void _startGameOverTimer() {
    _gameOverTimer?.cancel();
    _gameOverTimer = Timer(Duration(seconds: _gameOverThreshold), () {
      if (_gameState.isInactiveWarningShown && !_gameState.isGameOver) {
        _endGame();
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();

    if (_gameState.isInactiveWarningShown) {
      _gameOverTimer?.cancel();
      _gameState.setIsInactiveWarningShown(false);
    }
  }

  void _showInactivityWarning() {
    _gameState.setIsInactiveWarningShown(true);
    _startGameOverTimer();
  }

  void _endGame() {
    _gameState.setIsGameOver(true);
    _dataBinding.setWinner(
      _chatRoomId,
      _opponentId,
    ); // Opponent wins if current user is AFK
  }

  Future<void> handleDrawing(Offset point) async {
    _gameState.addPoint(point);
    // Only update points in database every 10 points to reduce flickering
    if (_gameState.points.length % 10 == 0) {
      await _dataBinding.updatePoints(_chatRoomId, _gameState.points);
    }
    _resetInactivityTimer();
  }

  Future<void> handleDrawingEnd() async {
    _gameState.addNullPoint();
    // Always update points when drawing ends to ensure final state is saved
    await _dataBinding.updatePoints(_chatRoomId, _gameState.points);
    _resetInactivityTimer();
  }

  Future<void> handleGuess(String guess) async {
    if (_gameState.isDrawer || _gameState.guessCorrect) return;

    _resetInactivityTimer(); // Reset timer on any user action

    final normalizedGuess = guess.trim().toLowerCase();
    final normalizedWord = _gameState.currentWord.toLowerCase();

    if (normalizedGuess == normalizedWord) {
      _gameState.setGuessCorrect(true);
      _gameState.incrementScore(_currentUserId);
      await _dataBinding.updateScores(_chatRoomId, _gameState.scores);

      if (_gameState.scores[_currentUserId]! >= _winningScore) {
        await _dataBinding.setWinner(_chatRoomId, _currentUserId);
        _gameState.setIsGameEnded(true);
      } else {
        await _swapRoles();
        await _prepareNewRound();
      }
    } else {
      _gameState.decrementAttempts();

      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Incorrect guess! ${_gameState.remainingAttempts} attempts remaining. Try again!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Check if this was the final attempt
      if (_gameState.remainingAttempts <= 0) {
        _gameState.incrementScore(_opponentId);
        await _dataBinding.updateScores(_chatRoomId, _gameState.scores);

        if (_gameState.scores[_opponentId]! >= _winningScore) {
          await _dataBinding.setWinner(_chatRoomId, _opponentId);
          _gameState.setIsGameEnded(true);
        } else {
          await _swapRoles();
          await _prepareNewRound();
        }
      }
    }
  }

  Future<void> _prepareNewRound() async {
    final newWord = GameUtils.getRandomWord();
    _gameState.setCurrentWord(newWord);
    await _dataBinding.updateGameModel(
      GameModel(
        chatRoomId: _chatRoomId,
        currentUserId: _currentUserId,
        opponentId: _opponentId,
        isDrawer: true,
        word: newWord,
        points: [],
        roles: {_currentUserId: 'drawer', _opponentId: 'guesser'},
        scores: _gameState.scores,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _swapRoles() async {
    // Get current roles from Firestore to ensure we have the latest state
    final game = await _dataBinding.getCurrentGame(_chatRoomId);
    if (game == null) return;

    // Determine new roles based on current roles
    final currentRoles = game.roles;
    final currentUserRole = currentRoles[_currentUserId];
    final opponentRole = currentRoles[_opponentId];

    // Swap roles for both users
    final newRoles = {
      _currentUserId: currentUserRole == 'drawer' ? 'guesser' : 'drawer',
      _opponentId: opponentRole == 'drawer' ? 'guesser' : 'drawer',
    };

    // Update local state
    _gameState.setIsDrawer(newRoles[_currentUserId] == 'drawer');
    _gameState.setGuessCorrect(false);
    _gameState.setRemainingAttempts(2);
    _gameState.clearPoints();

    // Update Firestore
    try {
      await _dataBinding.updateRoles(_chatRoomId, newRoles);
    } catch (e) {
      debugPrint('Failed to swap roles: $e');
    }
    await _dataBinding.updatePoints(_chatRoomId, []);
  }

  Future<void> clearCanvas() async {
    _gameState.clearPoints();
    await _dataBinding.updatePoints(_chatRoomId, []);
  }

  Future<void> resetGame() async {
    await _cleanupGame();
    _gameState.setIsGameEnded(
      true,
    ); // Ensure game ended state persists after reset for UI
  }

  Future<void> _cleanupGame() async {
    _inactivityTimer?.cancel();
    _gameState.reset();
    await _dataBinding.resetGame(_chatRoomId);
  }

  Future<void> handleExitGame() async {
    if (!_gameState.isGameEnded) {
      await _dataBinding.setWinner(_chatRoomId, _opponentId);
      _gameState.setWinner(_opponentId);
      _gameState.setWinnerDialogShown(true);
      _gameState.setIsGameEnded(true);
    }
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _gameOverTimer?.cancel();
  }
}
