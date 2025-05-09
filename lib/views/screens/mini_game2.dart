import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/game_state2.dart';
import '../../viewmodels/eventHandlers/game_event_handler2.dart';
import '../../viewmodels/dataBinding/game_data_binding2.dart';
import '../../services/game_service2.dart';
import '../../viewmodels/state/do_mission_state.dart';
import 'dart:async';

class MiniGame2Screen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String opponentId;
  final bool isPlayerX;

  const MiniGame2Screen({
    required this.chatRoomId,
    required this.currentUserId,
    required this.opponentId,
    required this.isPlayerX,
    super.key,
  });

  @override
  State<MiniGame2Screen> createState() => _MiniGame2ScreenState();
}

class _MiniGame2ScreenState extends State<MiniGame2Screen> {
  late GameState2 _gameState;
  late GameService2 _gameService;
  late GameDataBinding2 _dataBinding;
  late GameEventHandler2 _eventHandler;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _gameSubscription;
  bool _opponentLeft = false;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _setupGameListener();
  }

  void _setupGameListener() {
    _gameSubscription = _gameService.listenToGame(widget.chatRoomId).listen((
      snapshot,
    ) {
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        if (data['board'] != null) {
          _gameState.setBoard(List<String>.from(data['board']));
        }

        if (data['roles'] != null) {
          _gameState.setRoles(Map<String, String>.from(data['roles']));
        }

        if (data.containsKey('winner')) {
          if (_gameState.winner == null && !_isDialogShowing) {
            _gameState.setWinner(data['winner']);
            _gameState.setWinnerDialogShown(true);
          }
        }

        if (data['currentPlayer'] != null) {
          _gameState.setIsCurrentPlayer(
            data['currentPlayer'] == widget.currentUserId,
          );
        }

        final roles = Map<String, String>.from(data['roles'] ?? {});

        if (_gameState.isInitialized &&
            !roles.containsKey(widget.opponentId) &&
            _gameState.winner == null &&
            !_opponentLeft) {
          _handleOpponentLeft();
        }
      }
    });
  }

  void _handleOpponentLeft() {
    if (_opponentLeft || !mounted || _isDialogShowing || _gameState.winner != null) return;

    setState(() {
      _opponentLeft = true;
    });
    _showOpponentLeftDialog();
  }

  Future<void> _performEndGameCleanupAndExit() async {
    if (!mounted) return;
    _gameSubscription?.cancel();
    await _eventHandler.resetGame();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showOpponentLeftDialog() {
    if (!mounted || _isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("Opponent Left"),
          content: const Text("Your opponent has left the game. You win!"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performEndGameCleanupAndExit();
                _isDialogShowing = false;
              },
              child: const Text("Back to Chat"),
            ),
          ],
        ),
      ),
    ).then((_) => _isDialogShowing = false);
  }

  void _showInactivityDialog() {
    if (_gameState.isInactiveWarningShown || !mounted || _isDialogShowing) return;

    _isDialogShowing = true;
    _gameState.setInactiveWarningShown(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("Game Inactive"),
          content: const Text(
            "No moves were made for 2 minutes. The game will end.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performEndGameCleanupAndExit();
                _isDialogShowing = false;
              },
              child: const Text("Back to Chat"),
            ),
          ],
        ),
      ),
    ).then((_) => _isDialogShowing = false);
  }

  void _initializeGame() {
    _gameState = GameState2();
    _gameService = GameService2();
    _dataBinding = GameDataBinding2(
      gameService: _gameService,
      gameState: _gameState,
      currentUserId: widget.currentUserId,
    );
    
    final missionState = Provider.of<MissionState>(context, listen: false);
    
    _eventHandler = GameEventHandler2(
      gameState: _gameState,
      dataBinding: _dataBinding,
      chatRoomId: widget.chatRoomId,
      currentUserId: widget.currentUserId,
      opponentId: widget.opponentId,
      missionState: missionState,
    );
    _eventHandler.init(widget.isPlayerX);
    _gameState.startInactivityTimer();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _gameSubscription = null;
    _eventHandler.dispose();
    _gameState.reset();
    _isDialogShowing = false;
    super.dispose();
  }

  Future<bool> _handleUserExitRequest() async {
    if (_isDialogShowing) return false;
    _isDialogShowing = true;

    final confirmExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Exit Game"),
        content: const Text(
            "Are you sure you want to exit the game? Your opponent will win."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("Exit"),
          ),
        ],
      ),
    );

    if (confirmExit == true) {
      if (mounted) {
        _gameSubscription?.cancel();
        _gameSubscription = null;
        await _eventHandler.handleExitGame();
        if (mounted) {
          Navigator.of(context).pop();
        }
        _isDialogShowing = false;
        return true;
      } else {
        _isDialogShowing = false;
        return false;
      }
    } else {
      _isDialogShowing = false;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameState,
      child: Consumer<GameState2>(
        builder: (context, gameState, child) {
          if (gameState.winner != null && gameState.winnerDialogShown && !_isDialogShowing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && gameState.winner != null && !_isDialogShowing) {
                _showWinnerDialog(gameState.winner!);
              }
            });
            return _buildGameScreen(gameState);
          }

          if (!gameState.isInitialized && !gameState.isGameEnded) {
            return _buildLoadingScreen();
          }

          if (gameState.isInactive &&
              !gameState.isInactiveWarningShown &&
              !_isDialogShowing &&
              gameState.winner == null &&
              !_opponentLeft) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDialogShowing) {
                _showInactivityDialog();
              }
            });
          }

          return _buildGameScreen(gameState);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: Text("Tic Tac Toe")),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildGameScreen(GameState2 gameState) {
    return WillPopScope(
      onWillPop: _handleUserExitRequest,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Tic Tac Toe"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _handleUserExitRequest();
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameInfo(gameState),
              const SizedBox(height: 20),
              _buildBoard(gameState),
              const SizedBox(height: 20),
              _buildCurrentPlayer(gameState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameInfo(GameState2 gameState) {
    return Text(
      gameState.isCurrentPlayer
          ? "Your turn (${gameState.isPlayerX ? 'X' : 'O'})"
          : "Opponent's turn (${gameState.isPlayerX ? 'O' : 'X'})",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBoard(GameState2 gameState) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (gameState.isCurrentPlayer &&
                  gameState.board[index].isEmpty &&
                  gameState.winner == null) {
                _eventHandler.handleMove(index);
                gameState.resetInactivityTimer();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Text(
                  gameState.board[index],
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color:
                        gameState.board[index] == 'X'
                            ? Colors.blue
                            : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlayer(GameState2 gameState) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gameState.isCurrentPlayer ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        gameState.isCurrentPlayer ? "Your turn!" : "Waiting for opponent...",
        style: TextStyle(
          fontSize: 18,
          color:
              gameState.isCurrentPlayer ? Colors.green[900] : Colors.grey[700],
        ),
      ),
    );
  }

  void _showWinnerDialog(String winnerId) {
    final isSelf = winnerId == widget.currentUserId;
    final winnerName = isSelf ? "You" : "Opponent";
    final loserName = isSelf ? "Opponent" : "You";
    final isDraw = winnerId == 'draw';

    if (!mounted || _isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(isDraw ? "Game Draw!" : "Game Over!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDraw) ...[
                Text(
                  "🎉 $winnerName won the game!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text("😢 $loserName lost!", style: TextStyle(fontSize: 16)),
              ] else ...[
                Text(
                  "🤝 It's a draw!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performEndGameCleanupAndExit();
                _isDialogShowing = false;
              },
              child: const Text("Back to Chat"),
            ),
          ],
        ),
      ),
    ).then((_) {
      _isDialogShowing = false;
      if (mounted) {
        _gameState.setWinnerDialogShown(false);
      }
    });
  }
}
