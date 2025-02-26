import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatScreen({super.key, required this.chatRoomId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool partnerLeft = false;

  @override
  void initState() {
    super.initState();
    _listenForChatClosure();
  }

  // 🔹 Listen for Chat Closure & Exit Automatically
  void _listenForChatClosure() {
    _firestore.collection('chats').doc(widget.chatRoomId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('closed') &&
            data['closed'] == true) {
          setState(() {
            partnerLeft = true;
          });

          // Delay exit to allow showing "Partner has left" message
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          });
        }
      }
    });
  }

  // 🔹 Send Message to Firestore
  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _firestore
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
            'text': _messageController.text,
            'sender': _auth.currentUser!.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
      _messageController.clear();
    }
  }

  // 🔹 Close Chat Room (Marks as closed for both users)
  void _closeChatRoom() async {
    await _firestore.collection('chats').doc(widget.chatRoomId).update({
      'closed': true,
    });

    // Show "You left the chat" message for the current user
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closeChatRoom, // Close chat room for both users
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Show "Partner has left" message
          if (partnerLeft)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  "Your partner has left the chat.",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 🔹 Display Messages in Real Time
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  reverse: true,
                  children:
                      snapshot.data!.docs.map((doc) {
                        Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(data['text']),
                          subtitle: Text(data['sender']),
                        );
                      }).toList(),
                );
              },
            ),
          ),

          // 🔹 Message Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
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
    );
  }
}
