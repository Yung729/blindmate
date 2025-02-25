import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_socket_channel/io.dart';

// Message Model Class
class Message {
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Message(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatMatchmakingScreen(),
    );
  }
}

class ChatMatchmakingScreen extends StatefulWidget {
  const ChatMatchmakingScreen({super.key});

  @override
  _ChatMatchmakingScreenState createState() => _ChatMatchmakingScreenState();
}

class _ChatMatchmakingScreenState extends State<ChatMatchmakingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  IOWebSocketChannel? channel;
  User? user;
  String? matchedUserId;
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loginAnonymously();
  }

  Future<void> _loginAnonymously() async {
    UserCredential userCredential = await _auth.signInAnonymously();
    setState(() {
      user = userCredential.user;
    });
    _findMatch();
  }

  Future<void> _findMatch() async {
    QuerySnapshot users = await _firestore.collection('users').get();
    for (var doc in users.docs) {
      if (doc.id != user?.uid) {
        setState(() {
          matchedUserId = doc.id;
        });
        _connectToChat();
        return;
      }
    }
  }

  void _connectToChat() {
    if (matchedUserId != null) {
      channel = IOWebSocketChannel.connect('ws://yourserver.com/chat');
    }
  }

  void _sendMessage() {
    if (channel != null && messageController.text.isNotEmpty) {
      Message message = Message(
        senderId: user?.uid ?? '',
        receiverId: matchedUserId ?? '',
        text: messageController.text,
        timestamp: Timestamp.now(),
      );
      channel!.sink.add(message.text);
      _firestore.collection('messages').add(message.toFirestore());
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat & Matchmaking')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = Message.fromFirestore(messages[index]);
                    return ListTile(
                      title: Text(message.text),
                      subtitle: Text('From: ${message.senderId}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(hintText: 'Enter message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }
}
