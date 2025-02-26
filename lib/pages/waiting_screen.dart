import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class WaitingScreen extends StatefulWidget {
  final UserModel user;

  const WaitingScreen({super.key, required this.user});

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isNavigating = false; // Prevent duplicate navigation

  @override
  void initState() {
    super.initState();
    _startMatching();
    _listenForMatch();
  }

  // 🔹 Start Searching for a Match
  void _startMatching() async {
    await _chatService.updateUserStatus(widget.user.userId, 'waiting');

    // Try to find a match immediately
    String? chatRoomId = await _chatService.findMatch(widget.user);
    if (chatRoomId != null) {
      _navigateToChat(chatRoomId);
    }
  }

  // 🔹 Listen for Real-Time Match Updates
  void _listenForMatch() {
    _firestore
        .collection('chats')
        .where('users', arrayContains: widget.user.userId)
        .where('closed', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty && !_isNavigating) {
        String chatRoomId = querySnapshot.docs.first.id;
        _navigateToChat(chatRoomId);
      }
    });
  }

  // 🔹 Navigate to Chat
  void _navigateToChat(String chatRoomId) {
    if (_isNavigating) return; // Prevent multiple navigations
    _isNavigating = true;

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(chatRoomId: chatRoomId, currentUserId: widget.user.userId)),
      );
    }
  }

  // 🔹 Allow User to Cancel
  void _cancelSearch() async {
    await _chatService.updateUserStatus(widget.user.userId, 'available');
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Searching for a Match...")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Looking for a match... Please wait."),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _cancelSearch, child: const Text("Cancel")),
          ],
        ),
      ),
    );
  }
}
