import '../../services/game_service2.dart';
import '../state/game_state2.dart';

class GameDataBinding2 {
  final GameService2 _gameService;
  final GameState2 _gameState;
  final String _currentUserId;

  GameDataBinding2({
    required GameService2 gameService,
    required GameState2 gameState,
    required String currentUserId,
  }) : _gameService = gameService,
       _gameState = gameState,
       _currentUserId = currentUserId;

  Future<void> initializeGame(
    String chatRoomId,
    String currentUserId,
    String opponentId,
    bool isPlayerX,
  ) async {
    final game = await _gameService.getGame(chatRoomId);

    if (game != null) {
      final roles = Map<String, String>.from(game['roles'] ?? {});
      if (roles.containsKey(currentUserId) && roles.containsKey(opponentId)) {
        _gameState.setBoard(
          List<String>.from(game['board'] ?? List.filled(9, '')),
        );
        _gameState.setRoles(roles);
        _gameState.setWinner(game['winner']);
        _gameState.setIsPlayerX(roles[currentUserId] == 'X');
        _gameState.setIsCurrentPlayer(game['currentPlayer'] == currentUserId);
      } else {
        await _gameService.clearGame(chatRoomId);
        await _initializeNewGame(chatRoomId, currentUserId, opponentId, isPlayerX);
      }
    } else {
      await _initializeNewGame(chatRoomId, currentUserId, opponentId, isPlayerX);
    }

    _gameState.setIsInitialized(true);
  }

  Future<void> _initializeNewGame(
    String chatRoomId,
    String currentUserId,
    String opponentId,
    bool isPlayerX,
  ) async {
    final newGame = {
      'board': List<String>.filled(9, ''),
      'roles': <String, String>{
        currentUserId: isPlayerX ? 'X' : 'O',
        opponentId: isPlayerX ? 'O' : 'X',
      },
      'currentPlayer': currentUserId,
      'winner': null,
    };

    await _gameService.createGame(chatRoomId, newGame);
    _gameState.setBoard(newGame['board'] as List<String>);
    _gameState.setRoles(newGame['roles'] as Map<String, String>);
    _gameState.setIsPlayerX(isPlayerX);
    _gameState.setIsCurrentPlayer(true);
  }

  void listenToGame(String chatRoomId) {
    _gameService.listenToGame(chatRoomId).listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      if (data['board'] != null) {
        _gameState.setBoard(List<String>.from(data['board']));
      }

      if (data['roles'] != null) {
        _gameState.setRoles(Map<String, String>.from(data['roles']));
      }

      if (data.containsKey('winner')) {
        _gameState.setWinner(data['winner']);
        _gameState.setWinnerDialogShown(true);
      }

      if (data['currentPlayer'] != null) {
        _gameState.setIsCurrentPlayer(data['currentPlayer'] == _currentUserId);
      }
    });
  }

  Future<void> updateBoard(String chatRoomId, List<String> board) async {
    await _gameService.updateBoard(chatRoomId, board);
  }

  Future<void> updateRoles(String chatRoomId, Map<String, String> roles) async {
    await _gameService.updateRoles(chatRoomId, roles);
  }

  Future<void> setWinner(String chatRoomId, String winnerId) async {
    await _gameService.setWinner(chatRoomId, winnerId);
  }

  Future<void> clearGame(String chatRoomId) async {
    await _gameService.clearGame(chatRoomId);
  }

  Future<void> updateGame(
    String chatRoomId,
    Map<String, dynamic> gameData,
  ) async {
    await _gameService.updateGame(chatRoomId, gameData);
  }

  Future<void> resetGame(String chatRoomId) async {
    await _gameService.clearGame(chatRoomId);
    _gameState.reset();
    _gameState.setIsInitialized(false);
    _gameState.setWinnerDialogShown(false);
    _gameState.setBoard(List<String>.filled(9, ''));
    _gameState.setRoles({});
    _gameState.setWinner(null);
    _gameState.setIsPlayerX(false);
    _gameState.setIsCurrentPlayer(false);
  }
}
