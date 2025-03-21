import 'package:flutter/material.dart';
import '../../services/matching_service.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class WaitingScreen extends StatefulWidget {
  final UserModel user;

  const WaitingScreen({super.key, required this.user});

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> with SingleTickerProviderStateMixin {
  final MatchingService _matchingService = MatchingService();
  bool _isNavigating = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _startMatching();
    _listenForMatch();

    // ✅ Fix: Use SingleTickerProviderStateMixin
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

  // 🔹 Start Searching for a Match
  void _startMatching() async {
    String? chatRoomId = await _matchingService.startMatching(widget.user);
    if (chatRoomId != null) {
      _navigateToChat(chatRoomId);
    }
  }

  // 🔹 Listen for Real-Time Match Updates
  void _listenForMatch() {
    _matchingService.listenForMatch(widget.user.userId, (chatRoomId) {
      if (!_isNavigating) {
        _navigateToChat(chatRoomId);
      }
    });
  }

  // 🔹 Navigate to Chat
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

  // 🔹 Allow User to Cancel
  void _cancelSearch() async {
    await _matchingService.updateUserStatus(widget.user.userId, 'available');
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF02ABC1),
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation, // ✅ Fix: Use _scaleAnimation
              builder: (context, child) {
                return Transform.scale(scale: _scaleAnimation.value, child: child);
              },
              child: Image.asset(
                'assets/searching.gif',
                width: 200,
                height: 200,
              ),
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
