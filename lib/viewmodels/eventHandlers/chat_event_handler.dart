import 'dart:async';
import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/message_model.dart';
import '../state/chat_state.dart';
import '../dataBinding/chat_data_binding.dart';
import '../uiValidation/chat_validator.dart';
import 'package:blindmate/services/do_mission_service.dart';


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
    
    // Use microtask to schedule state updates without delaying UI
    Future.microtask(() {
      chatState.clear(); // Reset state when initializing new chat
      // Set the current user ID for tracking music playback
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
    if ((text == null || !MessageValidator.isValid(text)) &&
        (stickerUrl == null || stickerUrl.isEmpty) &&
        (musicUrl == null || musicUrl.isEmpty)) {
      print("❌ Invalid message, no content to send");
      return;
    }

    final message = MessageModel(
      senderId: currentUserId,
      text: text?.trim(),
      stickerUrl: stickerUrl,
      musicUrl: musicUrl,
      musicTitle: musicTitle,
      timestamp: DateTime.now(),
    );

    try {
      dataBinding.addMessage(message);
      await dataBinding.sendMessage(currentUserId, chatRoomId, message);
      resetInactivityTimer();

      // ✅ Track mission progress (safe messages)
    // ✅ Track mission progress for valid (safe) text messages
  if (text != null && MessageValidator.isValid(text)) {
    await trackUserMissionProgress(
  category: "chat",
  type: "action",
  actionCount: 1,
);
  }
    } catch (e) {
      if (e.toString().contains("BANNED")) {
        chatState.setBanned(true);
      }
      return;
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

  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 10), () {
      if (chatState.isChatOpen) {
        chatState.setInactive(true); // Add new state for inactivity
      }
    });
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }

  void _startInactivityTimer(BuildContext context) {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 10), () {
      if (chatState.isChatOpen) {
        chatState.setInactive(true); // Use new state instead of partnerLeft
      }
    });
  }
}
