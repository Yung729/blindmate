import 'dart:async';
import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/message_model.dart';
import '../state/chat_state.dart';
import '../dataBinding/chat_data_binding.dart';
import '../uiValidation/chat_validator.dart';

class ChatEventHandler {
  final ChatState chatState;
  final ChatDataBinding dataBinding;
  final MatchingEventHandler matchingHandler;

  final String chatRoomId;
  final String currentUserId;

  bool _isChatOpen = true;
  Timer? _inactivityTimer;
  Timer? _typingTimer;

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
    _isChatOpen = true;

    Future.microtask(() {
      chatState.clear(); // Reset state when initializing new chat
      chatState.setCurrentUserId(currentUserId);
    });

    dataBinding.initialize(chatRoomId, currentUserId);
    await dataBinding.fetchChatPartner(chatRoomId, currentUserId);
    dataBinding.listenTypingStatus(chatRoomId, chatState.otherUserId);
    await dataBinding.loadStickers("happy");
  }

  Future<void> searchStickers(String query) async {
    await dataBinding.loadStickers(query);
  }

  Future<void> sendMessage(
    BuildContext context, {
    String? text,
    String? stickerUrl,
    String? musicUrl,
    String? musicTitle,
  }) async {
    // Validate message has content
    bool hasText = text != null && MessageValidator.isValid(text);
    bool hasSticker = stickerUrl != null && stickerUrl.isNotEmpty;
    bool hasMusic = musicUrl != null && musicUrl.isNotEmpty;
    
    if (!hasText && !hasSticker && !hasMusic) {
      print("❌ Invalid message, no content to send");
      return;
    }

    final message = MessageModel(
      senderId: currentUserId,
      text: hasText ? text.trim() : null,
      stickerUrl: hasSticker ? stickerUrl : null,
      musicUrl: hasMusic ? musicUrl : null,
      musicTitle: hasMusic ? musicTitle : null,
      timestamp: DateTime.now(),
    );

    try {
      // Send message through data binding (which now adds it to state)
      await dataBinding.sendMessage(currentUserId, chatRoomId, message);
      resetInactivityTimer(context);
    } catch (e) {
      if (e.toString().contains("BANNED")) {
        chatState.setBanned(true);
      }
      print("❌ Error sending message: $e");
    }
  }

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

    try {
      await dataBinding.saveChatSummary(currentUserId, chatRoomId);
      await dataBinding.handleExit(chatRoomId, currentUserId);
      await matchingHandler.updateUserStatus(currentUserId, 'available');
    } finally {
      // Always dispose resources
      dispose();
    }

    print("✅ Chat exit complete for user: $currentUserId");
  }

  Future<void> reportUser() async {
    if (chatState.otherUserId == null) return;
    await dataBinding.reportUser(currentUserId, chatState.otherUserId!);
    chatState.setPartnerLeft(true); // Add this
    await dataBinding.closeChatRoom(chatRoomId);
  }

  void startInactivityTimer(BuildContext context) {
    _startInactivityTimer(context);
  }

  // Reset the inactivity timer when there's user activity
  void resetInactivityTimer(BuildContext context) {
    _inactivityTimer?.cancel();
    _startInactivityTimer(context);
  }

  // Clean up resources when chat is closed
  void dispose() {
    _inactivityTimer?.cancel();
    _typingTimer?.cancel();
    typingStatusSubscription?.cancel();
    chatUpdatesSubscription?.cancel();
  }

  // Start or restart the inactivity timer
  void _startInactivityTimer(BuildContext? context) {
    const inactivityDuration = Duration(minutes: 1);
    
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, () {
      if (chatState.isChatOpen) {
        chatState.setInactive(true);
      }
    });
  }

  Future<void> sendTripJournalMessage(
    BuildContext context,
    List<Map<String, dynamic>> tripJournals,
  ) async {
    print("SENDING trip journal message: $tripJournals");
    if (tripJournals.isEmpty) return;

    final message = MessageModel(
      senderId: currentUserId,
      tripJournals: tripJournals,
      timestamp: DateTime.now(),
      moderationStatus: 'SAFE', // Trip journals are considered safe by default
    );
    try {
      print("🧳 Adding trip journal message to local state");

      print("🧳 Sending trip journal message via WebSocket/Firestore");
      await dataBinding.sendMessage(currentUserId, chatRoomId, message);

      resetInactivityTimer(context);
      print("✅ Trip journal message sent successfully");
    } catch (e) {
      print(
        "❌ Error sending trip journal message: $e",
      ); // Handle error if needed
    }
  }
}
