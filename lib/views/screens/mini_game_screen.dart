import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/game_state.dart';
import '../../viewmodels/eventHandlers/game_event_handler.dart';
import '../../viewmodels/dataBinding/game_data_binding.dart';
import '../../services/game_service.dart';
import '../../viewmodels/uiValidation/game_validator.dart';
import 'chat_screen.dart';
import 'dart:ui';
import 'dart:async';

class MiniGameScreen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String opponentId;
  final bool isDrawer;

  const MiniGameScreen({
    required this.chatRoomId,
    required this.currentUserId,
    required this.opponentId,
    required this.isDrawer,
    super.key,
  });

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  late GameState _gameState;
  late GameService _gameService;
  late GameDataBinding _dataBinding;
  late GameEventHandler _eventHandler;
  final TextEditingController _guessController = TextEditingController();
  final GlobalKey _paintKey = GlobalKey();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _lastIsDrawer = false;
  StreamSubscription? _gameSubscription;
  bool _opponentLeft = false;

  @override
  void initState() {
    super.initState();
    _lastIsDrawer = widget.isDrawer;
    _initializeGame();
    _setupGameListener();
  }

  void _setupGameListener() {
    _gameSubscription = _gameService.listenToGame(widget.chatRoomId).listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final pointsData = data['points'] as List<dynamic>? ?? [];
        final updatedPoints =
            pointsData
                .map(
                  (point) =>
                      point == null
                          ? null
                          : Offset(
                            (point['dx'] as num).toDouble(),
                            (point['dy'] as num).toDouble(),
                          ),
                )
                .toList();

        _gameState.setPoints(updatedPoints); // <-- This triggers UI update

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
      builder:
          (context) => AlertDialog(
            title: Text("Opponent Left"),
            content: Text("Your opponent has left the game."),
            actions: [
              TextButton(
                onPressed: () async {
                  await _eventHandler.resetGame(); // <-- Add this
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatScreen(
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

  void _showWinnerDialog(String winnerId) {
    final isSelf = winnerId == widget.currentUserId;
    final winnerName = isSelf ? "You" : "Opponent";
    final loserName = isSelf ? "Opponent" : "You";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("🏁 Game Over"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🎉 $winnerName won the game!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text("😢 $loserName lost!", style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Text(
                  "Final Score:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$winnerName: ${_gameState.scores[winnerId] ?? 0} - $loserName: ${_gameState.scores[isSelf ? widget.opponentId : widget.currentUserId] ?? 0}",
                  style: TextStyle(fontSize: 16),
                ),
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
                        builder:
                            (context) => ChatScreen(
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

  void _initializeGame() {
    _gameState = GameState();
    _gameService = GameService();
    _dataBinding = GameDataBinding(
      gameService: _gameService,
      gameState: _gameState,
      currentUserId: widget.currentUserId, // <-- add this
    );
    _eventHandler = GameEventHandler(
      gameState: _gameState,
      dataBinding: _dataBinding,
      chatRoomId: widget.chatRoomId,
      currentUserId: widget.currentUserId,
      opponentId: widget.opponentId,
    );
    _eventHandler.init(widget.isDrawer);
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _eventHandler.dispose();
    _guessController.dispose();
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
      child: Consumer<GameState>(
        builder: (context, gameState, child) {
          if (!gameState.isInitialized) {
            return _buildLoadingScreen();
          }

          if (gameState.winner != null && gameState.winnerDialogShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWinnerDialog(gameState.winner!);
            });
          }

          // Show role swap message only when roles actually change
          if (gameState.isDrawer != _lastIsDrawer) {
            _lastIsDrawer = gameState.isDrawer;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSnackBar(
                gameState.isDrawer
                    ? "🎨 You are now the drawer! Draw: ${gameState.currentWord}"
                    : "🔍 You are now the guesser! Guess the word!",
              );
            });
          }

          // Only check for opponent leaving if the game is already initialized
          if (!_gameState.isInitialized) {
            _handleOpponentLeft();
          }

          return _buildGameScreen(gameState);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: Text("Draw & Guess")),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildGameScreen(GameState gameState) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Draw & Guess"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            // Show confirmation dialog
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
              // Notify opponent and return to chat
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
            _buildScoreDisplay(gameState),
            _buildDrawingArea(gameState),
            const SizedBox(height: 20),
            if (!gameState.isDrawer && !gameState.guessCorrect)
              _buildGuessInput(gameState),
            if (gameState.guessCorrect) _buildCorrectGuessMessage(),
            if (gameState.isDrawer) _buildClearButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo(GameState gameState) {
    return Text(
      gameState.isDrawer ? "Draw: ${gameState.currentWord}" : "Guess the word!",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildScoreDisplay(GameState gameState) {
    return Text(
      "Score: You ${gameState.scores[widget.currentUserId] ?? 0} - Opponent ${gameState.scores[widget.opponentId] ?? 0}",
      style: TextStyle(fontSize: 16),
    );
  }

  Widget _buildDrawingArea(GameState gameState) {
    return Container(
      key: _paintKey,
      width: 300,
      height: 300,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: GestureDetector(
        onPanUpdate:
            gameState.isDrawer
                ? (details) {
                  RenderBox renderBox =
                      _paintKey.currentContext!.findRenderObject() as RenderBox;
                  Offset localPosition = renderBox.globalToLocal(
                    details.globalPosition,
                  );

                  if (GameValidator.isValidPoint(localPosition, 300, 300)) {
                    _eventHandler.handleDrawing(localPosition);
                  }
                }
                : null,
        onPanEnd:
            gameState.isDrawer
                ? (details) => _eventHandler.handleDrawingEnd()
                : null,
        child: CustomPaint(
          painter: DrawingPainter(points: gameState.points),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildGuessInput(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          TextField(
            controller: _guessController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: "Enter your guess",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (GameValidator.isValidGuess(_guessController.text)) {
                _eventHandler.handleGuess(_guessController.text);
                _guessController.clear();
              }
            },
            child: Text("Submit Guess"),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectGuessMessage() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Text(
        "🎉 You guessed it right!",
        style: TextStyle(fontSize: 18, color: Colors.green),
      ),
    );
  }

  Widget _buildClearButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: ElevatedButton.icon(
        onPressed: () => _eventHandler.clearCanvas(),
        icon: Icon(Icons.clear),
        label: Text("Clear Drawing"),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.0
          ..isAntiAlias = true;

    // Group points into continuous segments
    List<List<Offset>> segments = [];
    List<Offset> currentSegment = [];

    for (var point in points) {
      if (point != null) {
        currentSegment.add(point);
      } else if (currentSegment.isNotEmpty) {
        segments.add(List.from(currentSegment));
        currentSegment.clear();
      }
    }

    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    // Draw each continuous segment
    for (var segment in segments) {
      if (segment.length < 2) continue;

      for (int i = 0; i < segment.length - 1; i++) {
        canvas.drawLine(segment[i], segment[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
