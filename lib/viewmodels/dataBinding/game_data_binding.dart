import '../../services/game_service.dart';
import '../state/game_state.dart';
import '../../models/dataModels/game_model.dart';
import '../../utils/game_utils.dart';
import 'package:flutter/material.dart';

class GameDataBinding {
  final GameService _gameService;
  final GameState _gameState;
  final String _currentUserId; // <-- ADD this

  GameDataBinding({
    required GameService gameService,
    required GameState gameState,
    required String currentUserId, // <-- ADD this
  }) : _gameService = gameService,
       _gameState = gameState,
       _currentUserId = currentUserId; // <-- SAVE it

  Future<GameModel?> getCurrentGame(String chatRoomId) async {
    return await _gameService.getGame(chatRoomId);
  }

  Future<void> updateGameModel(GameModel game) async {
    await _gameService.updateGame(game);
  }

  Future<void> initializeGame(
    String chatRoomId,
    String currentUserId,
    String opponentId,
    bool isDrawer,
  ) async {
    final game = await _gameService.getGame(chatRoomId);

    if (game != null) {
      _gameState.setPoints(game.points);
      _gameState.setIsDrawer(game.isDrawer);
      _gameState.setCurrentWord(game.word);
      _gameState.setScores(game.scores);
      _gameState.setWinner(game.winner);
    } else {
      final newGame = GameModel(
        chatRoomId: chatRoomId,
        currentUserId: currentUserId,
        opponentId: opponentId,
        isDrawer: isDrawer,
        word: GameUtils.getRandomWord(),
        points: [],
        roles: {
          currentUserId: isDrawer ? 'drawer' : 'guesser',
          opponentId: isDrawer ? 'guesser' : 'drawer',
        },
        scores: {currentUserId: 0, opponentId: 0},
        timestamp: DateTime.now(),
      );

      await _gameService.createGame(newGame);
      _gameState.setCurrentWord(newGame.word);
      _gameState.setScores(newGame.scores);
    }

    _gameState.setIsInitialized(true);
  }

  void listenToGame(String chatRoomId) {
    _gameService.listenToGame(chatRoomId).listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      // Only update points if they've actually changed
      if (data['points'] != null) {
        final newPoints = GameUtils.pointsFromMap(data['points'] as List);
        if (newPoints.length != _gameState.points.length) {
          _gameState.setPoints(newPoints);
        }
      }

      if (data['scores'] != null) {
        _gameState.setScores(Map<String, int>.from(data['scores']));
      }

      if (data.containsKey('winner')) {
        _gameState.setWinner(data['winner']);
        _gameState.setWinnerDialogShown(true);
      }

      if (data['roles'] != null) {
        final roles = Map<String, String>.from(data['roles']);
        final currentUserRole = roles[_currentUserId];
        if (currentUserRole != null) {
          _gameState.setIsDrawer(currentUserRole == 'drawer');
        }
      }

      if (data['word'] != null) {
        _gameState.setCurrentWord(data['word']);
      }
    });
  }

  Future<void> updatePoints(String chatRoomId, List<Offset?> points) async {
    try {
      await _gameService.updatePoints(chatRoomId, points);
    } catch (e) {
      debugPrint('Failed to update points: $e');
    }
  }

  Future<void> updateRoles(String chatRoomId, Map<String, String> roles) async {
    await _gameService.updateRoles(chatRoomId, roles);
  }

  Future<void> updateScores(String chatRoomId, Map<String, int> scores) async {
    await _gameService.updateScores(chatRoomId, scores);
  }

  Future<void> setWinner(String chatRoomId, String winnerId) async {
    await _gameService.setWinner(chatRoomId, winnerId);
  }

  Future<void> resetGame(String chatRoomId) async {
    await _gameService.clearGame(chatRoomId);
    _gameState.setPoints([]);
    _gameState.setIsDrawer(false);
    _gameState.setCurrentWord('');
    _gameState.setScores({});
    _gameState.setWinner(null);
    _gameState.setIsInitialized(false);
    _gameState.setWinnerDialogShown(false);
  }
}
