import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../models/dataModels/user_model.dart';
import 'chat_screen.dart';
import '../../viewmodels/eventHandlers/matching_event_handler.dart';
import '../../viewmodels/state/matching_state.dart';

class MatchingScreen extends StatefulWidget {
  final UserModel user;

  const MatchingScreen({super.key, required this.user});

  @override
  _MatchingScreenState createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with SingleTickerProviderStateMixin {
  late MatchingEventHandler _matchingHandler;
  late MatchingState _matchingState;
  bool _isNavigating = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _matchingState = context.read<MatchingState>();
    _matchingHandler = MatchingEventHandler(matchingState: _matchingState );
    _startMatching();
    _listenForMatch();

    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); 
    super.dispose();
  }

  void _startMatching() async {
    await _matchingHandler.startMatching(widget.user);
  }

  void _listenForMatch() {
    _matchingHandler.listenForMatch(widget.user.userId);
    _matchingState.addListener(() {
      if (_matchingState.chatRoomId != null && !_isNavigating) {
        _navigateToChat(_matchingState.chatRoomId!);
      }
    });
  }

  void _navigateToChat(String chatRoomId) {
    if (_isNavigating) return;
    _isNavigating = true;

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoomId,
            currentUserId: widget.user.userId,
          ),
        ),
      );
    }
  }

  void _cancelSearch() async {
    await _matchingHandler.updateUserStatus(widget.user.userId, 'available');
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sea background image
          Positioned.fill(
            child: Image.asset(
              'assets/sea_background.webp', // Add your sea background image here
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Lottie.asset(
              'assets/animated_boat.json', // Replace with your JSON animation file
              width: 500,
              height: 500,
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Finding your match...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _cancelSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    child: Text(
                      "Cancel Matching",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
