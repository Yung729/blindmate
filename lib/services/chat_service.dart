import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/dataModels/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String websocketUrl =
      "wss://blindmate-backend-production.up.railway.app";

  WebSocketChannel? _channel;
  final StreamController<List<MessageModel>> _messageStreamController =
      StreamController.broadcast();

  List<MessageModel> _messages = []; // Store all messages in memory

  /// 🔹 Connect WebSocket after finding a match
  void connectWebSocket(String chatRoomId) {
    _channel = IOWebSocketChannel.connect(websocketUrl);
    print("✅ WebSocket Connected to chatRoom: $chatRoomId");

    final connectMessage = jsonEncode({
      "type": "connect",
      "chatRoomId": chatRoomId, // ✅ No need for userId
    });
    _channel?.sink.add(connectMessage);

    _listenForMessages(chatRoomId); // ✅ Ensures real-time updates
  }

  void _listenForMessages(String chatRoomId) {
    _channel?.stream.listen((message) {
      try {
        final data = jsonDecode(message);

        if (data['type'] == 'message' && data['chatRoomId'] == chatRoomId) {
          print("✅ New Message Received!");

          MessageModel msg = MessageModel.fromMap(data);
          _messages.insert(0, msg);
          _messageStreamController.add(List.from(_messages));
        }
      } catch (e) {
        print("⚠️ WebSocket Error: $e");
      }
    }, cancelOnError: false);
  }

  /// 🔹 Get chat messages in real time
  Stream<List<MessageModel>> getMessages() {
    print("🎯 getMessages() Called");
    return _messageStreamController.stream.map((messages) {
      return messages;
    });
  }

  /// 🔹 Send a message via WebSocket
  Future<void> sendMessage(
    String userId,
    String chatRoomId,
    MessageModel message,
  ) async {
    final messageData = jsonEncode({
      "type": "message",
      "chatRoomId": chatRoomId, // ✅ Ensure chatRoomId is included
      "senderId": message.senderId,
      "text": message.text,
      "stickerUrl": message.stickerUrl,
      "timestamp": DateTime.now().toIso8601String(),
    });
    _channel?.sink.add(messageData);
    print("🚀 Sent WebSocket Message: $messageData");

    // Store message in Firestore
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMapForFirestore());
  }

  // 🔹 Listen for chat updates (when chat is closed)
  Stream<DocumentSnapshot> listenForChatUpdates(String chatRoomId) {
    return _firestore.collection('chats').doc(chatRoomId).snapshots();
  }

  Future<void> updateTypingStatus(
    String chatRoomId,
    String userId,
    bool isTyping,
  ) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).update(
      {'typing.$userId': isTyping},
    );
  }

  // 🔹 Close the chat room and reset users' status
  Future<void> closeChatRoom(String chatRoomId) async {
    await _firestore.collection('chats').doc(chatRoomId).update({
      'closed': true,
    });
  }

  /// 🔹 Close WebSocket connection
  void closeConnection() {
    _channel?.sink.close();
    _channel = null;
    print("❌ WebSocket Disconnected");
  }

  Future<void> reportUser(String reporterId, String reportedId) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, bool>> getTypingStatus(String chatRoomId) {
    return _firestore.collection('chats').doc(chatRoomId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('typing')) {
          return Map<String, bool>.from(data['typing']);
        }
      }
      return {};
    });
  }
}
