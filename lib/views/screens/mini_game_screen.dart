import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/game_state.dart';
import '../../viewmodels/eventHandlers/game_event_handler.dart';
import '../../viewmodels/dataBinding/game_data_binding.dart';
import '../../services/game_service.dart';
import '../../viewmodels/uiValidation/game_validator.dart';
import '../../viewmodels/state/do_mission_state.dart';
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
  bool _isDialogShowing = false;

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
      if (!mounted) return;

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

        // Only check for opponent leaving if the game is already initialized and no winner/dialog yet
        if (_gameState.isInitialized &&
            !roles.containsKey(widget.opponentId) &&
            _gameState.winner == null &&
            !_opponentLeft &&
            !_isDialogShowing) {
          _handleOpponentLeft();
        }
      }
    });
  }

  void _handleOpponentLeft() {
    if (_opponentLeft || !mounted || _isDialogShowing || _gameState.winner != null) return;

    // Use addPostFrameCallback to ensure setState is called after the build phase if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opponentLeft || _isDialogShowing || _gameState.winner != null) return; // Re-check
      setState(() {
        _opponentLeft = true;
      });
      _showOpponentLeftDialog();
    });
  }

  Future<void> _performEndGameCleanupAndExit({bool isForfeit = false}) async {
    if (!mounted) return;

    _gameSubscription?.cancel();
    _gameSubscription = null;

    if (!isForfeit) { // For regular game end (win, draw, opponent left, inactivity timeout)
      await _eventHandler.resetGame();
    } else { // For user explicitly exiting/forfeiting
      await _eventHandler.handleExitGame();
    }

    if (mounted) {
      // Pop only the current game screen to return to the previous screen (chat screen)
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
          content: const Text("Your opponent has left the game."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss this dialog
                await _performEndGameCleanupAndExit();
                // _isDialogShowing will be reset by .then() on showDialog
              },
              child: const Text("Back to Chat"),
            ),
          ],
        ),
      ),
    ).then((_) => _isDialogShowing = false);
  }

  void _showWinnerDialog(String winnerId) {
    final isSelf = winnerId == widget.currentUserId;
    final winnerName = isSelf ? "You" : "Opponent";
    final loserName = isSelf ? "Opponent" : "You";

    if (!mounted || _isDialogShowing) return;
    _isDialogShowing = true;
    // Ensure winnerDialogShown is managed correctly by GameState
    // and this dialog is only shown once.

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
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
                Navigator.of(dialogContext).pop(); // Dismiss this dialog
                await _performEndGameCleanupAndExit();
                 // _isDialogShowing will be reset by .then() on showDialog
              },
              child: const Text("Back to Chat"),
            ),
          ],
        ),
      ),
    ).then((_) {
        _isDialogShowing = false;
        if(mounted) {
            _gameState.setWinnerDialogShown(false); // Reset flag in GameState
        }
    });
  }

  void _showInactivityWarningDialog() {
    if (!mounted || _isDialogShowing) return;
    _isDialogShowing = true;
    // gameState.isInactiveWarningShown is already true, set by GameState timer

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Inactivity Warning"),
        content: const Text(
          "You have been inactive for 1 minute. Please continue playing or the game will end.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss this dialog
              _gameState.resetInactivityTimer(); // This also sets isInactiveWarningShown to false
              // _isDialogShowing will be reset by .then() on showDialog
            },
            child: const Text("Continue Playing"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Dismiss this dialog
              // This is a user-initiated forfeit from inactivity warning
              await _performEndGameCleanupAndExit(isForfeit: true);
              // _isDialogShowing will be reset by .then() on showDialog
            },
            child: const Text("Exit Game"),
          ),
        ],
      ),
    ).then((_) => _isDialogShowing = false);
  }

  void _showGameOverDialog() { // Due to inactivity
    if (!mounted || _isDialogShowing) return;
    _isDialogShowing = true;
    // gameState.isGameOver is already true, set by GameState timer

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text("Game Over"),
          content: const Text("The game has ended due to inactivity."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss this dialog
                await _performEndGameCleanupAndExit();
                // _isDialogShowing will be reset by .then() on showDialog
              },
              child: const Text("Back to Chat"),
            ),
          ],
        ),
      ),
    ).then((_) {
        _isDialogShowing = false;
        if(mounted) {
            _gameState.setIsGameOver(false); // Reset flag in GameState after dialog dismissal
        }
    });
  }

  void _initializeGame() {
    _gameState = GameState();
    _gameService = GameService();
    _dataBinding = GameDataBinding(
      gameService: _gameService,
      gameState: _gameState,
      currentUserId: widget.currentUserId,
    );
    
    // Get mission state from provider
    final missionState = Provider.of<MissionState>(context, listen: false);
    
    _eventHandler = GameEventHandler(
      gameState: _gameState,
      dataBinding: _dataBinding,
      chatRoomId: widget.chatRoomId,
      currentUserId: widget.currentUserId,
      opponentId: widget.opponentId,
      missionState: missionState,
    );
    _eventHandler.setContext(context);
    _eventHandler.init(widget.isDrawer);
  }

  @override
  void dispose() {
    // Make sure we properly clean up everything
    _gameSubscription?.cancel();
    _gameSubscription = null;
    _eventHandler.dispose();
    _guessController.dispose();
    _gameState.reset(); // This should cancel inactivity timer
    _isDialogShowing = false; // Ensure flag is reset
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  Future<bool> _handleUserExitRequest() async {
    if (_isDialogShowing) return false;
    _isDialogShowing = true;

    final confirmExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Exit Game"),
        content: const Text("Are you sure you want to exit the game? Your opponent will win."),
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
        // User confirmed exit. This is a forfeit.
        await _performEndGameCleanupAndExit(isForfeit: true);
        // _isDialogShowing is reset after dialog, and navigation happens in cleanup
        return true; // Signal that exit was handled.
      } else {
        _isDialogShowing = false; // Reset flag
        return false; // Cannot proceed.
      }
    } else {
      _isDialogShowing = false; // User cancelled.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameState,
      child: Consumer<GameState>(
        builder: (context, gameState, child) {
          // Show winner dialog at the highest priority
          if (gameState.winner != null && gameState.winnerDialogShown && !_isDialogShowing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && gameState.winner != null && !_isDialogShowing && gameState.winnerDialogShown) {
                _showWinnerDialog(gameState.winner!);
              }
            });
            // Return game screen to show content under dialog
            return _buildGameScreen(gameState);
          }

          // Only show loading when no end-game conditions and not initialized
          if (!gameState.isInitialized && !gameState.isGameEnded && gameState.winner == null) {
            return _buildLoadingScreen();
          }

          // Check for inactivity warning
          // GameState's timer sets isInactiveWarningShown to true directly.
          if (gameState.isInactiveWarningShown && !_isDialogShowing && gameState.winner == null && !_opponentLeft) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
              // Re-check flags just before showing to handle race conditions
              if (mounted && gameState.isInactiveWarningShown && !_isDialogShowing && gameState.winner == null && !_opponentLeft) {
                _showInactivityWarningDialog();
              }
            });
          }
          
          // Check for game over due to inactivity
          // GameState's timer sets isGameOver to true directly.
          if (gameState.isGameOver && !_isDialogShowing && gameState.winner == null && !_opponentLeft) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Re-check flags just before showing
              if (mounted && gameState.isGameOver && !_isDialogShowing && gameState.winner == null && !_opponentLeft ) {
                _showGameOverDialog();
              }
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

          // Opponent left is handled by the stream listener (_handleOpponentLeft)

          return _buildGameScreen(gameState);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text("Draw & Guess")),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildGameScreen(GameState gameState) {
    return WillPopScope(
        onWillPop: _handleUserExitRequest,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text("Draw & Guess", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue.shade700,
            elevation: 4,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleUserExitRequest, // Directly call, it handles pop if confirmed
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildGameInfo(gameState),
                    const SizedBox(height: 16),
                    _buildScoreDisplay(gameState),
                    const SizedBox(height: 8),
                    if (!gameState.isDrawer) _buildAttemptsDisplay(gameState),
                    const SizedBox(height: 8),
                    _buildDrawingArea(gameState),
                    const SizedBox(height: 16),
                    if (!gameState.isDrawer && !gameState.guessCorrect)
                      _buildGuessInput(gameState),
                    if (gameState.guessCorrect) _buildCorrectGuessMessage(),
                    if (gameState.showIncorrectGuess)
                      _buildIncorrectGuessMessage(gameState),
                    if (gameState.isDrawer) _buildClearButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildGameInfo(GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: gameState.isDrawer ? Colors.blue.shade100 : Colors.purple.shade100,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gameState.isDrawer ? Icons.brush : Icons.search,
            color: gameState.isDrawer ? Colors.blue.shade700 : Colors.purple.shade700,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              gameState.isDrawer ? "Draw: ${gameState.currentWord}" : "Guess the word!",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: gameState.isDrawer ? Colors.blue.shade700 : Colors.purple.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            "You: ${gameState.scores[widget.currentUserId] ?? 0}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(height: 16, width: 1, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "Opponent: ${gameState.scores[widget.opponentId] ?? 0}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsDisplay(GameState gameState) {
    final attemptsColor = gameState.remainingAttempts > 2 
        ? Colors.green 
        : (gameState.remainingAttempts > 1 ? Colors.orange : Colors.red);
        
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: attemptsColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: attemptsColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay, color: attemptsColor, size: 18),
          const SizedBox(width: 4),
          Text(
            "Attempts: ${gameState.remainingAttempts}",
            style: TextStyle(
              fontSize: 16,
              color: attemptsColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingArea(GameState gameState) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: NotificationListener<ScrollNotification>(
        // Prevent scroll events from propagating when interacting with drawing area
        onNotification: (ScrollNotification notification) {
          // Return true to cancel the notification bubbling
          return gameState.isDrawer;
        },
        child: Container(
          key: _paintKey,
          width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Background grid pattern
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/graphPaper.jpg'),
                      repeat: ImageRepeat.repeat,
                      opacity: 0.2,
                    ),
                  ),
                ),
                // Drawing area
                GestureDetector(
                  onPanUpdate: gameState.isDrawer
                      ? (details) {
                          RenderBox renderBox =
                              _paintKey.currentContext!.findRenderObject() as RenderBox;
                          Offset localPosition = renderBox.globalToLocal(
                            details.globalPosition,
                          );

                          final size = renderBox.size;
                          if (GameValidator.isValidPoint(localPosition, size.width, size.height)) {
                            _eventHandler.handleDrawing(localPosition);
                            _gameState.resetInactivityTimer();
                          }
                        }
                      : null,
                  onPanEnd: gameState.isDrawer
                      ? (details) => _eventHandler.handleDrawingEnd()
                      : null,
                  child: CustomPaint(
                    painter: DrawingPainter(points: gameState.points),
                    size: Size.infinite,
                  ),
                ),
                // Overlay message for guesser
                if (!gameState.isDrawer)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Guessing...",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuessInput(GameState gameState) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _guessController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: "Enter your guess",
              labelStyle: TextStyle(color: Colors.purple.shade700),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.lightbulb_outline, color: Colors.purple.shade700),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: (_) => _gameState.resetInactivityTimer(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (GameValidator.isValidGuess(_guessController.text)) {
                _eventHandler.handleGuess(_guessController.text);
                _guessController.clear();
                _gameState.resetInactivityTimer();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            child: const Text("Submit Guess", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectGuessMessage() {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          const Text(
            "You guessed it right!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.celebration, color: Colors.amber, size: 24),
        ],
      ),
    );
  }

  Widget _buildIncorrectGuessMessage(GameState gameState) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.close, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text(
                "Incorrect guess!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          if (gameState.remainingAttempts > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Try again! You have ${gameState.remainingAttempts} ${gameState.remainingAttempts == 1 ? 'attempt' : 'attempts'} left.",
                style: TextStyle(
                  fontSize: 16, 
                  color: gameState.remainingAttempts == 1 ? Colors.red.shade700 : Colors.orange.shade700,
                  fontWeight: gameState.remainingAttempts == 1 ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: ElevatedButton.icon(
        onPressed: () => _eventHandler.clearCanvas(),
        icon: const Icon(Icons.delete_sweep),
        label: const Text("Clear Drawing", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a subtle grid background
    _drawGrid(canvas, size);
    
    // Main drawing paint
    final paint = Paint()
      ..color = Colors.blue.shade800
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round;
    
    // Shadow paint for depth effect
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round;

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

    // Draw each continuous segment with shadow effect
    for (var segment in segments) {
      if (segment.length < 2) continue;

      // Draw shadow with slight offset
      for (int i = 0; i < segment.length - 1; i++) {
        canvas.drawLine(
          segment[i] + const Offset(1.5, 1.5), 
          segment[i + 1] + const Offset(1.5, 1.5), 
          shadowPaint
        );
      }
      
      // Draw the actual line
      for (int i = 0; i < segment.length - 1; i++) {
        canvas.drawLine(segment[i], segment[i + 1], paint);
      }
      
      // Draw dots at the start and end of each segment for better appearance
      if (segment.isNotEmpty) {
        canvas.drawCircle(segment.first, 2.5, paint);
        canvas.drawCircle(segment.last, 2.5, paint);
      }
    }
  }
  
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;
      
    const gridSize = 20.0;
    
    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    
    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
