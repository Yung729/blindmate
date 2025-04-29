import 'dart:async';
import 'package:flutter/material.dart';
import '../state/game_state.dart';
import '../dataBinding/game_data_binding.dart';
import '../../models/dataModels/game_model.dart';
import 'dart:ui' show Offset;
import '../../utils/game_utils.dart';

class GameEventHandler {
  final GameState _gameState;
  final GameDataBinding _dataBinding;
  final String _chatRoomId;
  final String _currentUserId;
  final String _opponentId;

  
  Timer? _inactivityTimer;
  Timer? _gameOverTimer;
  static const int _inactivityThreshold = 30; // 30 seconds of inactivity
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
    await _dataBinding.updatePoints(_chatRoomId, _gameState.points);
    _resetInactivityTimer();
  }

  Future<void> handleDrawingEnd() async {
    _gameState.addNullPoint();
    await _dataBinding.updatePoints(_chatRoomId, _gameState.points);
    _resetInactivityTimer();
  }

  Future<void> handleGuess(String guess) async {
    if (guess.isEmpty) return;

    _resetInactivityTimer(); // Reset timer on any user action

    final correct = guess.toLowerCase() == _gameState.currentWord.toLowerCase();

    if (correct) {
      _gameState.setGuessCorrect(true);
      _gameState.incrementScore(_currentUserId);
      await _dataBinding.updateScores(_chatRoomId, _gameState.scores);

      if (_gameState.scores[_currentUserId]! >= _winningScore) {
        await _dataBinding.setWinner(_chatRoomId, _currentUserId);
        _gameState.setIsGameEnded(true);
      } else {
        // // Get current game state before swapping roles
        // final game = await _dataBinding.getCurrentGame(_chatRoomId);
        // if (game == null) return;

        // // Swap roles: current guesser becomes drawer, current drawer becomes guesser
        // final newRoles = {
        //   _currentUserId: 'drawer',  // Current guesser becomes drawer
        //   _opponentId: 'guesser',    // Current drawer becomes guesser
        // };

        // // Update roles in Firestore first
        // await _dataBinding.updateRoles(_chatRoomId, newRoles);

        // // Then update local state
        // _gameState.setIsDrawer(true);  // Current user is now drawer
        // _gameState.setGuessCorrect(false);
        // _gameState.setRemainingAttempts(2);
        // _gameState.clearPoints();
        // await _dataBinding.updatePoints(_chatRoomId, []);

        // // Get a new word for the new drawer (current user)
        // final newWord = GameUtils.getRandomWord();
        // _gameState.setCurrentWord(newWord);

        // // Update the entire game model
        // await _dataBinding.updateGameModel(GameModel(
        //   chatRoomId: _chatRoomId,
        //   currentUserId: _currentUserId,
        //   opponentId: _opponentId,
        //   isDrawer: true,  // Current user is now drawer
        //   word: newWord,
        //   points: [],
        //   roles: newRoles,
        //   scores: _gameState.scores,
        //   timestamp: DateTime.now(),
        // ));

        await _swapRoles(); // <<<<< use existing helper
        await _prepareNewRound();
      }
    } else {
      _gameState.setRemainingAttempts(_gameState.remainingAttempts - 1);
      if (_gameState.remainingAttempts <= 0) {
        await _swapRoles(); // <<<<< use existing helper
        await _prepareNewRound();
        // _gameState.setRemainingAttempts(_gameState.remainingAttempts - 1);
        // if (_gameState.remainingAttempts <= 0) {
        //   // Get current game state before swapping roles
        //   final game = await _dataBinding.getCurrentGame(_chatRoomId);
        //   if (game == null) return;

        //   // Swap roles: current guesser becomes drawer, current drawer becomes guesser
        //   final newRoles = {
        //     _currentUserId: 'drawer',  // Current guesser becomes drawer
        //     _opponentId: 'guesser',    // Current drawer becomes guesser
        //   };

        //   // Update roles in Firestore first
        //   await _dataBinding.updateRoles(_chatRoomId, newRoles);

        //   // Then update local state
        //   _gameState.setIsDrawer(true);  // Current user is now drawer
        //   _gameState.setGuessCorrect(false);
        //   _gameState.setRemainingAttempts(2);
        //   _gameState.clearPoints();
        //   await _dataBinding.updatePoints(_chatRoomId, []);

        //   // Get a new word for the new drawer (current user)
        //   final newWord = GameUtils.getRandomWord();
        //   _gameState.setCurrentWord(newWord);

        //   // Update the entire game model
        //   await _dataBinding.updateGameModel(GameModel(
        //     chatRoomId: _chatRoomId,
        //     currentUserId: _currentUserId,
        //     opponentId: _opponentId,
        //     isDrawer: true,  // Current user is now drawer
        //     word: newWord,
        //     points: [],
        //     roles: newRoles,
        //     scores: _gameState.scores,
        //     timestamp: DateTime.now(),
        //   ));
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
    await _dataBinding.clearGame(_chatRoomId);
    _gameState.reset();
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _gameOverTimer?.cancel();
    
  }
}
