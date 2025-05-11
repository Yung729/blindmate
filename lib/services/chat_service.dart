import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/dataModels/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String websocketUrl = "wss://blindmate-backend-chat.up.railway.app";

  WebSocketChannel? _channel;
  final StreamController<MessageModel> _messageStreamController =
      StreamController.broadcast();
  String? _currentUserId;

  // Track sent message IDs to avoid duplicates
  final Set<String> _sentMessageIds = {};

  /// Helper to serialize tripJournals dates as strings
  List<Map<String, dynamic>> serializeTripJournals(
    List<Map<String, dynamic>> journals,
  ) {
    return journals.map((journal) {
      final newJournal = Map<String, dynamic>.from(journal);
      if (newJournal['date'] is DateTime) {
        newJournal['date'] = (newJournal['date'] as DateTime).toIso8601String();
      }
      return newJournal;
    }).toList();
  }

  /// 🔹 Connect WebSocket after finding a match
  void connectWebSocket(String chatRoomId, String userId) {
    _currentUserId = userId; // Store current user ID
    _channel = IOWebSocketChannel.connect(websocketUrl);
    print("✅ WebSocket Connected to chatRoom: $chatRoomId");

    final connectMessage = jsonEncode({
      "type": "connect",
      "chatRoomId": chatRoomId,
    });
    _channel?.sink.add(connectMessage);

    _listenForMessages(chatRoomId);
  }

  // Track received message IDs to prevent duplicates
  final Set<String> _receivedMessageIds = {};

  void _listenForMessages(String chatRoomId) {
    _channel?.stream.listen((message) {
      try {
        final data = jsonDecode(message);

        if (data['type'] == 'message' && data['chatRoomId'] == chatRoomId) {
          // Use fromWebSocket instead of fromMap for WebSocket messages
          MessageModel msg = MessageModel.fromWebSocket(data);

          // Check if this message has already been processed
          if (_receivedMessageIds.contains(msg.messageId)) {
            print("🔄 Skipping duplicate message: ${msg.messageId}");
            return;
          }

          // Track the message ID to avoid duplicates
          _receivedMessageIds.add(msg.messageId);

          // Skip messages from current user - they will be added directly to state when sent
          if (msg.senderId == _currentUserId) {
            print("👤 Skipping own message in WebSocket listener: ${msg.messageId}");
            return;
          }
          
          // Broadcast the message to listeners (only for messages from other users)
          _messageStreamController.add(msg);
          print("✅ Added message with ID ${msg.messageId} from ${msg.senderId}");
        }
      } catch (e) {
        print("⚠️ WebSocket Error: $e");
      }
    }, cancelOnError: false);
  }

  /// 🔹 Get chat messages in real time
  Stream<MessageModel> getMessages() {
    print("🎯 getMessages() Called");
    return _messageStreamController.stream;
  }

  /// 🔹 Send a message via WebSocket
  /// Returns the message that was sent (with any modifications)
  Future<MessageModel> sendMessage(
    String userId,
    String chatRoomId,
    MessageModel message,
  ) async {

    if (message.moderationStatus == 'SENSITIVE') {
      message = message.copyWith(moderationStatus: 'WARNING');
    }

    final Map<String, dynamic> messageMap = {
      "type": "message",
      "messageId": message.messageId,
      "chatRoomId": chatRoomId,
      "senderId": message.senderId,
      "timestamp": DateTime.now().toIso8601String(),
      "moderationStatus": message.moderationStatus,
    };

    // Only add non-null fields to avoid issues with null values
    if (message.text != null) messageMap["text"] = message.text;
    if (message.stickerUrl != null) {
      messageMap["stickerUrl"] = message.stickerUrl;
    }
    if (message.musicUrl != null && message.musicUrl!.isNotEmpty) {
      messageMap["musicUrl"] = message.musicUrl;
      print("🎵 Added musicUrl to WebSocket message: ${message.musicUrl}");
    }
    if (message.musicTitle != null && message.musicTitle!.isNotEmpty) {
      messageMap["musicTitle"] = message.musicTitle;
      print("🎵 Added musicTitle to WebSocket message: ${message.musicTitle}");
    }
    if (message.tripJournals != null && message.tripJournals!.isNotEmpty) {
      messageMap["tripJournals"] = serializeTripJournals(message.tripJournals!);
    }

    final messageData = jsonEncode(messageMap);
    _channel?.sink.add(messageData);
    print("🚀 Sent WebSocket Message: $messageData");

    // Track this message ID as sent by the current user
    _sentMessageIds.add(message.messageId);
    print("📝 Tracking sent message ID: ${message.messageId}");

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toMapForFirestore());

    return message; // Return the message so it can be added to the state
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
      'closedAt': FieldValue.serverTimestamp(),
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

  Future<List<String>> getChatUsers(String chatRoomId) async {
    final chatDoc = await _firestore.collection('chats').doc(chatRoomId).get();
    if (!chatDoc.exists) return [];
    return List<String>.from(chatDoc['users']);
  }

  Future<Map<String, dynamic>?> fetchChatPartner(
    String chatRoomId,
    String currentUserId,
  ) async {
    final chatDoc = await _firestore.collection('chats').doc(chatRoomId).get();
    if (!chatDoc.exists) return null;

    List<String> users = List<String>.from(chatDoc['users']);
    users.remove(currentUserId);

    if (users.isEmpty) return null;

    // Get the partner's user ID
    final partnerId = users.first;

    // Fetch the partner's user data to get their avatar
    final partnerDoc =
        await _firestore.collection('users').doc(partnerId).get();
    String? avatarImg;

    if (partnerDoc.exists && partnerDoc.data() != null) {
      avatarImg = partnerDoc.data()!['avatarImg'] as String?;
    }

    return {'partnerId': partnerId, 'avatarImg': avatarImg ?? ''};
  }

  Future<void> saveChatSummary(
    String chatRoomId,
    Map<String, dynamic> summary,
  ) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('summaries')
          .doc(summary['userId']) // Use userId as document ID
          .set(summary);

      print("✅ Chat summary saved successfully for user: ${summary['userId']}");
    } catch (e) {
      print("❌ Error saving chat summary: $e");
      throw Exception("Failed to save chat summary");
    }
  }
}
