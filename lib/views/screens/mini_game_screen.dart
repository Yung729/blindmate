import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';  // Adjust the path based on your project structure
import 'dart:async'; // Import for Timer

class MiniGameScreen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String opponentId;
  final bool isDrawer; // true = drawing, false = guessing

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
  List<Offset?> points = [];
  final GlobalKey _paintKey = GlobalKey();
  final TextEditingController _guessController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _words = ["Sunflower", "Rocket", "Pizza", "Tree"];
  late String _currentWord;
  late bool _isDrawer;
  bool _guessCorrect = false;
  bool _isInitialized = false;
  bool _winnerDialogShown = false;
  bool _isGameEnded = false;
  int _remainingAttempts = 2;
  
  late Timer _inactivityTimer;
  late Timer _gameOverTimer; // Timer for game over if inactivity continues
  static const int _inactivityThreshold = 10; // Inactivity threshold in seconds
  static const int _gameOverThreshold = 5; // Time until game ends after inactivity warning
  bool _isInactiveWarningShown = false; // Flag to check if warning has been shown
  bool _isGameOver = false; // Flag to track if the game is over


  @override
  void initState() {
    super.initState();
    _listenToGameState();

    _firestore.collection('games').doc(widget.chatRoomId).get().then((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data != null && data['roles'] != null) {
        final roles = data['roles'] as Map<String, dynamic>;
        _isDrawer = roles[widget.currentUserId] == 'drawer';
      } else {
        _isDrawer = widget.isDrawer; // fallback
      }

      // Set current word if exists
      if (data != null && data['word'] != null) {
        _currentWord = data['word'];
      } else {
        _currentWord = _getRandomWord();
        _updateGameData(); // Save to Firestore if no word exists yet
      }

      if (!_isDrawer) {
        _listenToDrawing();
      }

      setState(() {
        _isInitialized = true;
      });

       _startInactivityTimer(); // Start the inactivity timer when the game is initialized
       //_startGameOverTimer(); // Start the timer for game over after inactivity warning
    });

    _firestore.collection('games').doc(widget.chatRoomId).snapshots().listen((snapshot) {
  if (!mounted || _isGameEnded) return;

  final data = snapshot.data();
  if (data != null && data['winner'] != null && !_winnerDialogShown) {
    final String winnerId = data['winner'];
    _winnerDialogShown = true;
    _isGameEnded = true;
    _showWinnerDialog(winnerId);
  }
});

  }

  @override
  void dispose() {
    _inactivityTimer.cancel(); // Cancel the timer when the screen is disposed
    _gameOverTimer.cancel(); // <-- Add this
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer = Timer.periodic(Duration(seconds: _inactivityThreshold), (timer) {
      // Show a popup if the user has been inactive
      _showInactivityWarning();
    });
  }

  // 3. Timer to end the game after inactivity persists
void _startGameOverTimer() {
  _gameOverTimer = Timer(Duration(seconds: _gameOverThreshold), () {
    if (_isInactiveWarningShown && !_isGameOver) {
      // If inactivity persists after the warning, end the game
      _endGame();
    }
  });
}

  void _resetInactivityTimer() {
  _inactivityTimer.cancel();
  _startInactivityTimer();

  // Cancel game over timer if warning was shown and user is active now
  if (_isInactiveWarningShown) {
    _gameOverTimer.cancel();       // Cancel the game over timer
    _isInactiveWarningShown = false; // Clear the flag so warning can show again later
  }
}

  void _showInactivityWarning() {
    

     if (!_isGameEnded && !_isInactiveWarningShown) {
      setState(() {
        _isInactiveWarningShown = true; // Mark that the warning has been shown
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text("⏰ Inactivity Warning"),
          content: Text("It seems like you've been inactive for a while. Please make a move."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetInactivityTimer(); // Reset the timer after clicking "OK"
                setState(() {
                  _isInactiveWarningShown = false; // Reset the flag when the user acknowledges
                });
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );

      _startGameOverTimer();
    }
  }


  Future<void> _updateGameData() async {
    final docRef = _firestore.collection('games').doc(widget.chatRoomId);
    final snapshot = await docRef.get();

    final existingScores =
        snapshot.data()?['scores'] as Map<String, dynamic>? ?? {};

    final Map<String, int> scores = {
      widget.currentUserId: existingScores[widget.currentUserId] ?? 0,
      widget.opponentId: existingScores[widget.opponentId] ?? 0,
    };

    final Map<String, String> roles = {
      widget.currentUserId: _isDrawer ? 'drawer' : 'guesser',
      widget.opponentId: _isDrawer ? 'guesser' : 'drawer',
    };

    await docRef.set({
      'points':
          points.map((e) {
            if (e == null) return {'dx': null, 'dy': null};
            return {'dx': e.dx, 'dy': e.dy};
          }).toList(),
      'word': _currentWord,
      'roles': roles,
      'scores': scores,
    }, SetOptions(merge: true));
  }

  // 4. Method to end the game after inactivity
void _endGame() {
  setState(() {
    _isGameOver = true;
  });

  // Show game over dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text("Game Over"),
      content: Text("You have been inactive for too long. The game has ended."),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Reset the game or navigate to chat screen
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

  void _listenToGameState() {
    _firestore.collection('games').doc(widget.chatRoomId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final roles = data['roles'] as Map<String, dynamic>?;

        if (roles != null && roles.containsKey(widget.currentUserId)) {
          final newRole = roles[widget.currentUserId];
          final isNowDrawer = newRole == 'drawer';

          if (_isDrawer != isNowDrawer) {
            setState(() {
              _isDrawer = isNowDrawer;
              _guessCorrect = false;
              points.clear();
            });

            if (!_isDrawer) {
              _listenToDrawing();
            }
          }
        }

        final newWord = data['word'] as String?;
        if (newWord != null && newWord != _currentWord) {
          setState(() {
            _currentWord = newWord;
          });
        }
      }
    });
  }

  void _listenToDrawing() {
    _firestore.collection('games').doc(widget.chatRoomId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final List<dynamic> rawPoints = data['points'] ?? [];
        setState(() {
          points =
              rawPoints.map<Offset?>((pt) {
                if (pt['dx'] == null || pt['dy'] == null) return null;
                return Offset(pt['dx'], pt['dy']);
              }).toList();
        });
          _resetInactivityTimer(); // Reset inactivity timer when new drawing data is received
      }
    });
  }

  String _getRandomWord() {
    _words.shuffle();
    return _words.first;
  }

  void clearCanvas() {
    setState(() => points.clear());
    _firestore.collection('games').doc(widget.chatRoomId).update({
      'points': [],
    });
  }

  void submitGuess() {
  String guess = _guessController.text.trim().toLowerCase();
  if (guess.isEmpty) return;

  final correct = guess == _currentWord.toLowerCase();

  if (correct) {
    setState(() {
      _guessCorrect = true;
    });

    _firestore.collection('games').doc(widget.chatRoomId).get().then((doc) {
      final data = doc.data()!;
      final Map<String, dynamic> scores = data['scores'] ?? {};

      int currentScore = (scores[widget.currentUserId] ?? 0) + 1;
      scores[widget.currentUserId] = currentScore;

      _firestore.collection('games').doc(widget.chatRoomId).update({
        'scores': scores,
      });

      if (currentScore >= 1) {
        _firestore.collection('games').doc(widget.chatRoomId).update({
          'scores': scores,
          'winner': widget.currentUserId,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 Correct! Swapping roles...")),
        );
        Future.delayed(Duration(seconds: 2), _swapRoles);
      }
    });
  } else {
    _remainingAttempts--;

    if (_remainingAttempts > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Wrong! You have $_remainingAttempts tries left.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("😢 No more tries! Swapping roles...")),
      );
      Future.delayed(Duration(seconds: 2), _swapRoles);
    }
  }

  _guessController.clear();
}

 void _showWinnerDialog(String winnerId) async {
  final isSelf = winnerId == widget.currentUserId;

  String winnerName = "Someone";

  try {
    final snapshot = await _firestore.collection('users').doc(winnerId).get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['name'] != null) {
        winnerName = data['name'];
      }
    }
  } catch (e) {
    print("Error fetching winner name: $e");
  }

  if (!mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text("🏁 Game Over"),
      content: Text(
        isSelf
            ? "🎉 You won the game!"
            : "😢 You lost! The winner is $winnerName",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog

            // Reset game state for the new round
            _resetGameState();

            // Use Navigator.pushReplacement to replace the current screen (MiniGameScreen) with ChatScreen
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

void _resetGameState() {
  // Randomly assign roles
  final roles = _assignRolesRandomly();

  setState(() {
    points.clear();
    _guessCorrect = false;
    _remainingAttempts = 2;
    _isGameEnded = false;
    _winnerDialogShown = false;
    _currentWord = _getRandomWord();  // Assign a new word for the next round
  });

  // Reset the Firestore document with new roles
  _firestore.collection('games').doc(widget.chatRoomId).update({
    'points': [],
    'word': _currentWord,
    'scores': {
      widget.currentUserId: 0,
      widget.opponentId: 0,
    },
    'roles': roles,  // Update roles
    'winner': null,
  });
}

Map<String, String> _assignRolesRandomly() {
  // Randomly assign the drawer and guesser roles
  final roles = [widget.currentUserId, widget.opponentId]..shuffle();

  return {
    roles[0]: 'drawer',
    roles[1]: 'guesser',
  };
}

  void _swapRoles() {
  setState(() {
    _isDrawer = !_isDrawer;
    _currentWord = _getRandomWord();
    _guessCorrect = false;
    _remainingAttempts = 2; // ⬅️ Reset on new round
    points.clear();
  });

  final roles = {
    widget.currentUserId: _isDrawer ? 'drawer' : 'guesser',
    widget.opponentId: _isDrawer ? 'guesser' : 'drawer',
  };

  _firestore.collection('games').doc(widget.chatRoomId).update({
    'roles': roles,
    'word': _currentWord,
    'points': [],
  });
}


  void _sendPointsToFirestore() async {
    final List<Map<String, dynamic>> pointMap =
        points.map((e) {
          if (e == null) return {'dx': null, 'dy': null}; // 👈 keep nulls
          return {'dx': e.dx, 'dy': e.dy};
        }).toList();

    await _firestore.collection('games').doc(widget.chatRoomId).set({
      'points': pointMap,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text("Draw & Guess")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Draw & Guess")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isDrawer ? "Draw: $_currentWord" : "Guess the word!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore
                      .collection('games')
                      .doc(widget.chatRoomId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final scores = data['scores'] as Map<String, dynamic>? ?? {};
                final myScore = scores[widget.currentUserId] ?? 0;
                final opponentScore = scores[widget.opponentId] ?? 0;

                return Text(
                  "Score: You $myScore - Opponent $opponentScore",
                  style: TextStyle(fontSize: 16),
                );
              },
            ),

            /// 🎨 Drawing Area
            Container(
              key: _paintKey,
              width: 300,
              height: 300,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: GestureDetector(
                onPanUpdate:
                    _isDrawer
                        ? (details) {
                          RenderBox renderBox =
                              _paintKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          Offset localPosition = renderBox.globalToLocal(
                            details.globalPosition,
                          );

                          if (localPosition.dx >= 0 &&
                              localPosition.dy >= 0 &&
                              localPosition.dx <= 300 &&
                              localPosition.dy <= 300) {
                            setState(() {
                              points.add(localPosition);
                            });
                            _updateGameData();
                             _resetInactivityTimer(); // Reset inactivity timer when drawing
                          }
                        }
                        : null,
                onPanEnd:
                    _isDrawer
                        ? (details) => setState(() => points.add(null))
                        : null,
                child: CustomPaint(
                  painter: DrawingPainter(points: points),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// 💬 Guessing TextField
            if (!_isDrawer && !_guessCorrect)
              Padding(
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
                      onPressed: submitGuess,
                      child: Text("Submit Guess"),
                    ),
                  ],
                ),
              ),

            /// 🎉 Guess Correct Message
            if (_guessCorrect)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "🎉 You guessed it right!",
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ),

            /// 🧹 Clear Drawing Button
            if (_isDrawer)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton.icon(
                  onPressed: clearCanvas,
                  icon: Icon(Icons.clear),
                  label: Text("Clear Drawing"),
                ),
              ),
          ],
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
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}