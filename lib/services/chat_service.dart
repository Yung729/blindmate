import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

  // 🔹 Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({'status': status});
  }

  // 🔹 Find a match ensuring different mental health levels
  Future<String?> findMatch(UserModel user) async {
    print("🔍 Searching for a match for user: ${user.userId}");

    // Fetch list of users **reported by the current user**
    final reportedByMeSnapshot =
        await _firestore
            .collection('reports')
            .where('reporterId', isEqualTo: user.userId)
            .get();

    List<String> reportedByMe =
        reportedByMeSnapshot.docs
            .map((doc) => doc['reportedId'] as String)
            .toList();

    print("🚫 Users I reported: ${reportedByMe.length}");

    // Fetch list of users **who reported the current user**
    final reportedMeSnapshot =
        await _firestore
            .collection('reports')
            .where('reportedId', isEqualTo: user.userId)
            .get();

    List<String> reportedMe =
        reportedMeSnapshot.docs
            .map((doc) => doc['reporterId'] as String)
            .toList();

    print("🚫 Users who reported me: ${reportedMe.length}");

    final querySnapshot =
        await _firestore
            .collection('users')
            .where('status', isEqualTo: 'waiting')
            .where('online', isEqualTo: true)
            .get();

    print("✅ Found ${querySnapshot.docs.length} potential matches");

    List<UserModel> potentialMatches =
        querySnapshot.docs
            .where((doc) => doc.id != user.userId)
            .map(
              (doc) =>
                  UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .where(
              (matchedUser) =>
                  matchedUser.mentalHealthLevel != user.mentalHealthLevel &&
                  !reportedByMe.contains(matchedUser.userId) &&
                  !reportedMe.contains(matchedUser.userId),
            )
            .toList();

    print("🎯 Filtered down to ${potentialMatches.length} valid matches");

    if (potentialMatches.isNotEmpty) {
      Random random = Random();
      UserModel matchedUser =
          potentialMatches[random.nextInt(potentialMatches.length)];

      String chatRoomId = _firestore.collection('chats').doc().id;
      print(
        "🚀 Creating chat room: $chatRoomId between ${user.userId} and ${matchedUser.userId}",
      );

      // **🔹 Immediately update both users to "in_chat" before creating chat room**
      await updateUserStatus(user.userId, 'in_chat');
      await updateUserStatus(matchedUser.userId, 'in_chat');

      // **🔹 Create the chat room**
      await _firestore.collection('chats').doc(chatRoomId).set({
        'users': [user.userId, matchedUser.userId],
        'createdAt': FieldValue.serverTimestamp(),
        'closed': false,
      });

      print("✅ Chat room $chatRoomId successfully created");

      return chatRoomId;
    }

    print("❌ No match found");
    return null;
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
  Future<void> closeChatRoom(String chatRoomId, List<String> users) async {
    await _firestore.collection('chats').doc(chatRoomId).update({
      'closed': true,
    });

    // 🔹 Ensure Firestore updates properly
    await Future.delayed(const Duration(milliseconds: 1000));

    for (String userId in users) {
      await updateUserStatus(userId, 'available');
    }

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
}
