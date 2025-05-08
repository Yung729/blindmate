import 'dart:async';
import '../state/game_state2.dart';
import '../dataBinding/game_data_binding2.dart';
import '../eventHandlers/mission_event_handler.dart';
import '../state/do_mission_state.dart';

class GameEventHandler2 {
  final GameState2 _gameState;
  final GameDataBinding2 _dataBinding;
  final String _chatRoomId;
  final String _currentUserId;
  final String _opponentId;
  final MissionEventHandler? _missionEventHandler;

  Timer? _inactivityTimer;
  static const int _inactivityThreshold = 30; // 30 seconds of inactivity

  GameEventHandler2({
    required GameState2 gameState,
    required GameDataBinding2 dataBinding,
    required String chatRoomId,
    required String currentUserId,
    required String opponentId,
    MissionState? missionState,
  }) : _gameState = gameState,
       _dataBinding = dataBinding,
       _chatRoomId = chatRoomId,
       _currentUserId = currentUserId,
       _opponentId = opponentId,
       _missionEventHandler = missionState != null ? MissionEventHandler(missionState: missionState) : null;

  Future<void> init(bool isPlayerX) async {
    await _dataBinding.initializeGame(
      _chatRoomId,
      _currentUserId,
      _opponentId,
      isPlayerX,
    );
    _dataBinding.listenToGame(_chatRoomId);
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(Duration(seconds: _inactivityThreshold), (
      timer,
    ) {
      if (!_gameState.winnerDialogShown && !_gameState.isGameEnded) {
        _handleOpponentTimeout();
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }

  Future<void> _handleOpponentTimeout() async {
    if (!_gameState.isGameEnded) {
      await _dataBinding.setWinner(_chatRoomId, _currentUserId);
      _gameState.setWinner(_currentUserId);
      _gameState.setWinnerDialogShown(true);
      _gameState.setIsGameEnded(true);
      await _cleanupGame();
    }
  }

  Future<void> handleMove(int index) async {
    if (!_gameState.isCurrentPlayer ||
        _gameState.board[index].isNotEmpty ||
        _gameState.isGameEnded)
      return;

    final newBoard = List<String>.from(_gameState.board);
    newBoard[index] = _gameState.isPlayerX ? 'X' : 'O';

    // Check for winner
    final winner = _checkWinner(newBoard);
    if (winner != null) {
      await _dataBinding.setWinner(_chatRoomId, winner);
      _gameState.setWinner(winner);
      _gameState.setWinnerDialogShown(true);
      _gameState.setIsGameEnded(true);
      await _cleanupGame();
      return;
    }

    // Check for draw
    if (!newBoard.contains('')) {
      await _dataBinding.setWinner(_chatRoomId, 'draw');
      _gameState.setWinner('draw');
      _gameState.setWinnerDialogShown(true);
      _gameState.setIsGameEnded(true);
      await _cleanupGame();
      return;
    }

    // Update board and switch turns
    await _dataBinding.updateBoard(_chatRoomId, newBoard);
    _gameState.setBoard(newBoard);

    // Switch current player
    final newCurrentPlayer =
        _gameState.isCurrentPlayer ? _opponentId : _currentUserId;
    await _dataBinding.updateGame(_chatRoomId, {
      'currentPlayer': newCurrentPlayer,
    });
    _gameState.setIsCurrentPlayer(newCurrentPlayer == _currentUserId);

    _resetInactivityTimer();
  }

  String? _checkWinner(List<String> board) {
    // Check rows
    for (int i = 0; i < 9; i += 3) {
      if (board[i].isNotEmpty &&
          board[i] == board[i + 1] &&
          board[i] == board[i + 2]) {
        return _gameState.roles[_currentUserId] == board[i]
            ? _currentUserId
            : _opponentId;
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[i].isNotEmpty &&
          board[i] == board[i + 3] &&
          board[i] == board[i + 6]) {
        return _gameState.roles[_currentUserId] == board[i]
            ? _currentUserId
            : _opponentId;
      }
    }

    // Check diagonals
    if (board[0].isNotEmpty && board[0] == board[4] && board[0] == board[8]) {
      return _gameState.roles[_currentUserId] == board[0]
          ? _currentUserId
          : _opponentId;
    }
    if (board[2].isNotEmpty && board[2] == board[4] && board[2] == board[6]) {
      return _gameState.roles[_currentUserId] == board[2]
          ? _currentUserId
          : _opponentId;
    }

    return null;
  }

  Future<void> handleExitGame() async {
    if (!_gameState.isGameEnded) {
      await _dataBinding.setWinner(_chatRoomId, _opponentId);
      _gameState.setWinner(_opponentId);
      _gameState.setWinnerDialogShown(true);
      _gameState.setIsGameEnded(true);
    }
  }

  Future<void> _cleanupGame() async {
    _inactivityTimer?.cancel();
    
    // Track mission progress when game is completed
    if (_missionEventHandler != null) {
      await _missionEventHandler.trackMissionProgress(
        category: 'chat',
        type: 'action',
        actionCount: 1,
        actionType: 'game',
      );
    }
    
    _gameState.reset();
    await _dataBinding.resetGame(_chatRoomId);
  }

  Future<void> resetGame() async {
    await _cleanupGame();
    _gameState.setIsGameEnded(
      true,
    ); // Ensure game ended state persists after reset for UI
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }
}
