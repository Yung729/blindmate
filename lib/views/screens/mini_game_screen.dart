import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/game_state.dart';
import '../../viewmodels/eventHandlers/game_event_handler.dart';
import '../../viewmodels/dataBinding/game_data_binding.dart';
import '../../services/game_service.dart';
import '../../viewmodels/uiValidation/game_validator.dart';
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
    _gameState.startInactivityTimer();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _opponentLeft = true;
        });
        _showOpponentLeftDialog();
      });
    }
  }

  void _showOpponentLeftDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text("Opponent Left"),
              content: Text("Your opponent has left the game."),
              actions: [
                TextButton(
                  onPressed: () async {
                    // First dismiss the dialog
                    Navigator.of(context).pop();

                    // Force cleanup and state reset
                    _gameSubscription?.cancel();
                    await _eventHandler.resetGame();

                    // Only one navigation needed for opponent left
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Back to Chat"),
                ),
              ],
            ),
          ),
    );
  }

  void _showWinnerDialog(String winnerId) {
    final isSelf = winnerId == widget.currentUserId;
    final winnerName = isSelf ? "You" : "Opponent";
    final loserName = isSelf ? "Opponent" : "You";

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
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
                    // First dismiss the dialog
                    Navigator.of(context).pop();

                    // Force cleanup and state reset
                    _gameSubscription?.cancel();
                    await _eventHandler.resetGame();

                    // Force navigation back no matter what
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop(); // This pop takes us from game screen to chat screen
                    }
                  },
                  child: const Text("Back to Chat"),
                ),
              ],
            ),
          ),
    );
  }

  void _showInactivityWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Inactivity Warning"),
            content: Text(
              "You have been inactive for 1 minute. Please continue playing or the game will end.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _gameState.resetInactivityTimer();
                  Navigator.pop(context);
                },
                child: Text("Continue Playing"),
              ),
              TextButton(
                onPressed: () async {
                  // First dismiss the dialog
                  Navigator.of(context).pop();

                  // Force cleanup and state reset
                  _gameSubscription?.cancel();
                  await _eventHandler.resetGame();

                  // Force navigation back no matter what
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Exit Game"),
              ),
            ],
          ),
    );
  }

  void _showGameOverDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text("Game Over"),
              content: Text("The game has ended due to inactivity."),
              actions: [
                TextButton(
                  onPressed: () async {
                    // First dismiss the dialog
                    Navigator.of(context).pop();

                    // Force cleanup and state reset
                    _gameSubscription?.cancel();
                    await _eventHandler.resetGame();

                    // Force navigation back no matter what
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Back to Chat"),
                ),
              ],
            ),
          ),
    );
  }

  void _initializeGame() {
    _gameState = GameState();
    _gameService = GameService();
    _dataBinding = GameDataBinding(
      gameService: _gameService,
      gameState: _gameState,
      currentUserId: widget.currentUserId,
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
    // Make sure we properly clean up everything
    _gameSubscription?.cancel();
    _eventHandler.dispose();
    _guessController.dispose();
    _gameState.reset();
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
          // Show winner dialog at the highest priority
          if (gameState.winner != null && gameState.winnerDialogShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWinnerDialog(gameState.winner!);
            });
            // Return game screen to show content under dialog
            return _buildGameScreen(gameState);
          }

          // Only show loading when no end-game conditions and not initialized
          if (!gameState.isInitialized && !gameState.isGameEnded) {
            return _buildLoadingScreen();
          }

          if (gameState.isInactiveWarningShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showInactivityWarningDialog();
            });
          }

          if (gameState.isGameOver) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showGameOverDialog();
            });
          }

          // Show role swap message only when roles actually change
          if (gameState.isDrawer != _lastIsDrawer) {
            _lastIsDrawer = gameState.isDrawer;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Only show message to the relevant player
              if (gameState.isDrawer == widget.isDrawer) {
                _showSnackBar(
                  gameState.isDrawer
                      ? "🎨 You are now the drawer! Draw: ${gameState.currentWord}"
                      : "🔍 You are now the guesser! Guess the word!",
                );
              }
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
            final shouldExit = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => AlertDialog(
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
              // First handle game exit with forced cleanup
              _gameSubscription?.cancel();
              await _eventHandler.handleExitGame();

              // When user exits, only need one navigation
              if (mounted) {
                Navigator.of(context).pop();
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
            if (!gameState.isDrawer) _buildAttemptsDisplay(gameState),
            _buildDrawingArea(gameState),
            const SizedBox(height: 20),
            if (!gameState.isDrawer && !gameState.guessCorrect)
              _buildGuessInput(gameState),
            if (gameState.guessCorrect) _buildCorrectGuessMessage(),
            if (gameState.showIncorrectGuess)
              _buildIncorrectGuessMessage(gameState),
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

  Widget _buildAttemptsDisplay(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        "Attempts remaining: ${gameState.remainingAttempts}",
        style: TextStyle(
          fontSize: 16,
          color: gameState.remainingAttempts == 1 ? Colors.red : Colors.black,
          fontWeight:
              gameState.remainingAttempts == 1
                  ? FontWeight.bold
                  : FontWeight.normal,
        ),
      ),
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
                    _gameState.resetInactivityTimer();
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
            onChanged: (_) => _gameState.resetInactivityTimer(),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (GameValidator.isValidGuess(_guessController.text)) {
                _eventHandler.handleGuess(_guessController.text);
                _guessController.clear();
                _gameState.resetInactivityTimer();
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

  Widget _buildIncorrectGuessMessage(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Text(
            "❌ Incorrect guess!",
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          if (gameState.remainingAttempts > 0)
            Text(
              "Try again!",
              style: TextStyle(fontSize: 16, color: Colors.orange),
            ),
        ],
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
