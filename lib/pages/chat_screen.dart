import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import 'home_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;

  const ChatScreen({super.key, required this.chatRoomId, required this.currentUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool partnerLeft = false;
  bool _isChatOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔹 Listen for chat closure (partner leaving)
    _chatService.listenForChatUpdates(widget.chatRoomId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data['closed'] == true) {
          setState(() => partnerLeft = true);
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔹 Detect app lifecycle changes (Close chat when app is closed)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _handleExit();
    }
  }

  // 🔹 Handle closing the chat room
  Future<void> _handleExit({bool isManualClose = false}) async {
    if (!_isChatOpen) return; // Prevent multiple updates
    _isChatOpen = false;

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .get();

    if (chatDoc.exists) {
      List<String> users = List<String>.from(chatDoc['users']);
      users.remove(widget.currentUserId);

      if (users.isEmpty || isManualClose) {
        // 🔥 No users left or manual close → Close chat room
        await _chatService.closeChatRoom(widget.chatRoomId, users);
      } else {
        // 🔹 Mark user as "available" but keep chat open
        await _chatService.updateUserStatus(widget.currentUserId, 'available');
      }
    }

    if (isManualClose) {
      // 🔹 Navigate back after closing chat
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        widget.chatRoomId,
        MessageModel(
          senderId: widget.currentUserId,
          text: _messageController.text.trim(),
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleExit(); // Handle back button exit
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chat"),
          actions: [
            // 🔹 Close Chat Button
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                await _handleExit(isManualClose: true);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              // 🔹 Listen for messages in real-time
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatRoomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<MessageModel> messages = snapshot.data!;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      MessageModel message = messages[index];
                      bool isMe = message.senderId == widget.currentUserId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(message.text, style: const TextStyle(fontSize: 16)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 🔹 Message Input
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
