import 'dart:async';
import 'package:blindmate/models/api/giphy_service.dart';
import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dataModels/message_model.dart';
import '../state/chat_state.dart';
import '../dataBinding/chat_data_binding.dart';

class ChatEventHandler {
  final ChatState chatState;
  final ChatDataBinding dataBinding;
  final MatchingEventHandler matchingHandler;

  final String chatRoomId;
  final String currentUserId;

  bool _isChatOpen = true;
  Timer? _inactivityTimer;

  final _giphyService = GiphyService();

  StreamSubscription? typingStatusSubscription;
  StreamSubscription? chatUpdatesSubscription;

  ChatEventHandler({
    required this.chatState,
    required this.dataBinding,
    required this.matchingHandler,
    required this.chatRoomId,
    required this.currentUserId,
  });

  Future<void> init() async {
    dataBinding.initialize(chatRoomId);
    await fetchChatPartner();
    dataBinding.listenTypingStatus(chatRoomId, chatState.otherUserId);
    await loadStickers("happy");
  }

  Future<void> fetchChatPartner() async {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).get();
    if (chatDoc.exists) {
      List<String> users = List<String>.from(chatDoc['users']);
      users.remove(currentUserId);
      if (users.isNotEmpty) {
        dataBinding.setOtherUserId(users.first);
      }
    }
  }

  Future<void> loadStickers(String query) async {
    try {
      List<String> stickers = await _giphyService.fetchStickers(query);
      dataBinding.setStickers(stickers);
    } catch (e) {
      debugPrint("❌ Failed to load stickers: $e");
    }
  }

  Future<void> sendMessage({String? text, String? stickerUrl}) async {
    if ((text == null || text.trim().isEmpty) && (stickerUrl == null || stickerUrl.isEmpty)) {
      return;
    }

    final message = MessageModel(
      senderId: currentUserId,
      text: text?.trim(),
      stickerUrl: stickerUrl,
      timestamp: DateTime.now(),
    );

    dataBinding.addMessage(message); // Optimistic UI update
    await dataBinding.sendMessage(currentUserId, chatRoomId, message);
    resetInactivityTimer(); // ✅ Reset inactivity timer on sending
  }

  Timer? _typingTimer;

  void updateTyping(bool isTyping) {
    _typingTimer?.cancel();
    if (isTyping) {
      dataBinding.updateTyping(chatRoomId, currentUserId, true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        dataBinding.updateTyping(chatRoomId, currentUserId, false);
      });
    } else {
      dataBinding.updateTyping(chatRoomId, currentUserId, false);
    }
  }

  Future<void> handleExit() async {
    if (!_isChatOpen) return;
    _isChatOpen = false;

    print("🚪 Closing chat room for user: $currentUserId");

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) return;

    List<String> users = List<String>.from(chatDoc['users']);
    users.remove(currentUserId);

    dataBinding.closeConnection();
    print("🚪 Chat WebSocket disconnected");

    if (users.isEmpty) {
      await dataBinding.closeChatRoom(chatRoomId); // Close room when alone
      print("✅ Chat room closed by last user");
    } else {
      await chatRef.update({'closed': true});
      print("✅ Chat room marked closed");
    }

    await matchingHandler.updateUserStatus(currentUserId, 'available');
    dataBinding.clearChatState();

    print("✅ Chat exit complete for user: $currentUserId");
  }

  Future<void> reportUser(BuildContext context) async {
    if (chatState.otherUserId == null) return;

    await dataBinding.reportUser(currentUserId, chatState.otherUserId!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User reported. You will not match again.")),
    );

    await handleExit();
  }

  Future<void> confirmEndChat(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Chat?"),
        content: const Text("Are you sure you want to leave this chat? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await handleExit();
            },
            child: const Text("End Chat", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void startInactivityTimer(BuildContext context) {
    _startInactivityTimer(context);
  }

  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 10), () {
      print("User inactive for 10 minutes. Chat should close.");
    });
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }

  void _startInactivityTimer(BuildContext context) {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 10), () {
      _showInactivityDialog(context);
    });
  }

  Future<void> _showInactivityDialog(BuildContext context) async {
    bool? shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chat Ended Due to Inactivity"),
        content: const Text("No messages were sent for 10 minutes. This chat will now close."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              handleExit();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await handleExit();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
}
