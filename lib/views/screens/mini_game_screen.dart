import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    Key? key,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _listenToGameState();

    _firestore.collection('games').doc(widget.chatRoomId).get().then((snapshot) {
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
  });
    //old version
    // _isDrawer = widget.isDrawer;
    // _currentWord = _getRandomWord();
    // if (!widget.isDrawer) {
    //   _listenToDrawing();
    // }

    
  }

  Future<void> _updateGameData() async {
  final Map<String, String> roles = {
    widget.currentUserId: _isDrawer ? 'drawer' : 'guesser',
    widget.opponentId: _isDrawer ? 'guesser' : 'drawer',
  };

  await _firestore.collection('games').doc(widget.chatRoomId).set({
    'points': points.map((e) {
      if (e == null) return {'dx': null, 'dy': null};
      return {'dx': e.dx, 'dy': e.dy};
    }).toList(),
    'word': _currentWord,
    'roles': roles,
  }, SetOptions(merge: true));
}

  void _listenToGameState() {
  _firestore.collection('games').doc(widget.chatRoomId).snapshots().listen((snapshot) {
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
      }
    });
  }

  String _getRandomWord() {
    _words.shuffle();
    return _words.first;
  }

  void clearCanvas() {
    setState(() => points.clear());
    _firestore.collection('games').doc(widget.chatRoomId).update({'points': []});
  }

  void submitGuess() {
    String guess = _guessController.text.trim().toLowerCase();
    if (guess.isEmpty) return;

    if (guess == _currentWord.toLowerCase()) {
      setState(() {
        _guessCorrect = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("🎉 Correct! Swapping roles...")));

      Future.delayed(Duration(seconds: 2), () {
        _swapRoles();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Try again!")));
    }

    _guessController.clear();
  }

  void _swapRoles() {
  setState(() {
    _isDrawer = !_isDrawer;
    _currentWord = _getRandomWord();
    _guessCorrect = false;
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
  //_updateGameData();
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