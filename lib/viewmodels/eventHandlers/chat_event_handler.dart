import 'dart:async';
import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:flutter/material.dart';
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
    dataBinding.initialize(chatRoomId);
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
  }) async {
    if ((text == null || text.trim().isEmpty) &&
        (stickerUrl == null || stickerUrl.isEmpty)) {
      return;
    }

    final message = MessageModel(
      senderId: currentUserId,
      text: text?.trim(),
      stickerUrl: stickerUrl,
      timestamp: DateTime.now(),
    );

    try {
      dataBinding.addMessage(message);
      await dataBinding.sendMessage(currentUserId, chatRoomId, message);
      resetInactivityTimer();
    } catch (e) {
      if (e.toString().contains("BANNED")) {
        await _handleBan(context);
      }
      return;
    }
  }

  Future<void> _handleBan(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text("Account Warning"),
            content: const Text(
              "You have been removed from this chat due to multiple inappropriate messages. "
              "Please be mindful of our community guidelines.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await handleExit();
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text("Understood"),
              ),
            ],
          ),
    );
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

    await dataBinding.saveChatSummary(currentUserId, chatRoomId);
    await dataBinding.handleExit(chatRoomId, currentUserId);
    await matchingHandler.updateUserStatus(currentUserId, 'available');

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
