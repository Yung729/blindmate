import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/game_state2.dart';
import '../../viewmodels/eventHandlers/game_event_handler2.dart';
import '../../viewmodels/dataBinding/game_data_binding2.dart';
import '../../services/game_service2.dart';
import '../../viewmodels/uiValidation/game_validator2.dart';
import 'chat_screen.dart';
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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription? _gameSubscription;
  bool _opponentLeft = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _setupGameListener();
  }

  void _setupGameListener() {
    _gameSubscription = _gameService.listenToGame(widget.chatRoomId).listen((snapshot) {
      if (snapshot.exists) {
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
          _gameState.setIsCurrentPlayer(data['currentPlayer'] == widget.currentUserId);
        }

        // Role/leave check
        final roles = Map<String, String>.from(data['roles'] ?? {});

        // Only check for opponent leaving if the game is already initialized
        if (_gameState.isInitialized && !roles.containsKey(widget.opponentId)) {
          _handleOpponentLeft();
        }
      }
    });
  }

  void _handleOpponentLeft() {
    if (!_opponentLeft && mounted) {
      setState(() {
        _opponentLeft = true;
      });
      _showOpponentLeftDialog();
    }
  }

  void _showOpponentLeftDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Opponent Left"),
        content: Text("Your opponent has left the game."),
        actions: [
          TextButton(
            onPressed: () async {
              await _eventHandler.resetGame();
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: widget.chatRoomId,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showInactivityDialog() {
    if (_gameState.isInactiveWarningShown) return;
    
    _gameState.setInactiveWarningShown(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Game Inactive"),
        content: Text("No moves were made for 2 minutes. The game will end."),
        actions: [
          TextButton(
            onPressed: () async {
              await _eventHandler.resetGame();
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: widget.chatRoomId,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _initializeGame() {
    _gameState = GameState2();
    _gameService = GameService2();
    _dataBinding = GameDataBinding2(
      gameService: _gameService,
      gameState: _gameState,
      currentUserId: widget.currentUserId,
    );
    _eventHandler = GameEventHandler2(
      gameState: _gameState,
      dataBinding: _dataBinding,
      chatRoomId: widget.chatRoomId,
      currentUserId: widget.currentUserId,
      opponentId: widget.opponentId,
    );
    _eventHandler.init(widget.isPlayerX);
    _gameState.startInactivityTimer();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _eventHandler.dispose();
    _gameState.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameState,
      child: Consumer<GameState2>(
        builder: (context, gameState, child) {
          if (!gameState.isInitialized) {
            return _buildLoadingScreen();
          }

          if (gameState.winner != null && gameState.winnerDialogShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWinnerDialog(gameState.winner!);
            });
          }

          if (gameState.isInactive && !gameState.isInactiveWarningShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showInactivityDialog();
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Tic Tac Toe"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text("Exit Game"),
                content: Text("Are you sure you want to exit the game?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("Exit"),
                  ),
                ],
              ),
            );

            if (shouldExit == true && mounted) {
              await _eventHandler.handleExitGame();
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: widget.chatRoomId,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              }
            }
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
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
                    color: gameState.board[index] == 'X'
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
          color: gameState.isCurrentPlayer ? Colors.green[900] : Colors.grey[700],
        ),
      ),
    );
  }

  void _showWinnerDialog(String winnerId) {
    final isSelf = winnerId == widget.currentUserId;
    final winnerName = isSelf ? "You" : "Opponent";
    final loserName = isSelf ? "Opponent" : "You";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("🏁 Game Over"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winnerId == 'draw' 
                ? "🤝 It's a draw!" 
                : "🎉 $winnerName won the game!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (winnerId != 'draw') ...[
              SizedBox(height: 8),
              Text("😢 $loserName lost!", style: TextStyle(fontSize: 16)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _eventHandler.resetGame();
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: widget.chatRoomId,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
} 