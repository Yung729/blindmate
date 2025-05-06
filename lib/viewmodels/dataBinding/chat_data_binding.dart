import 'dart:async';
import 'package:blindmate/models/api/giphy_service.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:blindmate/services/reward_service.dart';
import 'package:blindmate/viewmodels/eventHandlers/mission_event_handler.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../models/dataModels/message_model.dart';
import '../state/chat_state.dart';
import '../../services/trip_journal_service.dart';

class ChatDataBinding {
  final ChatService _chatService = ChatService();
  final GiphyService _giphyService = GiphyService();
  final GeminiModerationService _moderationService = GeminiModerationService();
  final UserTripJournalService _tripJournalService = UserTripJournalService();
  final RewardService _rewardService = RewardService();
  final ChatState chatState;
  late MissionEventHandler _missionEventHandler;

  ChatDataBinding({required this.chatState, MissionState? missionState}) {
    if (missionState != null) {
      _missionEventHandler = MissionEventHandler(missionState: missionState);
    }
  }

  void initialize(String chatRoomId, String userId) async {
    // Initialize network connections
    _chatService.connectWebSocket(chatRoomId, userId);

    // Set up listeners for incoming messages
    _chatService.getMessages().listen((message) {
      // Use microtask to avoid blocking the UI thread
      Future.microtask(() {
        // Only add messages that aren't already in the state
        if (!chatState.messages.any((m) => m.messageId == message.messageId)) {
          chatState.addMessage(message);
          print("✅ Added incoming message: ${message.messageId}");
        } else {
          print("🔄 Skipping duplicate message: ${message.messageId}");
        }
      });
    });

    _chatService.listenForChatUpdates(chatRoomId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data['closed'] == true) {
          // Use microtask for better performance
          Future.microtask(() {
            chatState.setPartnerLeft(true);
          });
        }
      }
    });
  }

  Future<void> loadStickers(String query) async {
    var isPositive = false;
    try {
      chatState.setIsLoadingStickers(true);

      // Check if the sticker search query is positive using Gemini
      if (query != 'happy') {
        isPositive = await _moderationService.isStickerSearchPositive(query);

        debugPrint("🔍 Sticker search query: '$query' isPositive: $isPositive");
      }

      if (isPositive || query == 'happy') {
        List<String> stickers = await _giphyService.fetchStickers(query);
        setStickers(stickers);
      } else {
        // If negative, don't search and show an error message
        chatState.setErrorMessage(
          "🚫 Search blocked: Only positive sticker searches are allowed",
        );
        debugPrint("⛔ Negative sticker search blocked: '$query'");
      }
    } catch (e) {
      debugPrint("❌ Failed to load stickers: $e");
    } finally {
      chatState.setIsLoadingStickers(false);
    }
  }

  void listenTypingStatus(String chatRoomId, String? otherUserId) {
    if (otherUserId == null) {
      debugPrint('⚠️ listenTypingStatus called with null otherUserId');
      return;
    }

    _chatService.getTypingStatus(chatRoomId).listen((typingData) {
      bool isTyping = typingData[otherUserId] == true;
      chatState.setOtherUserTyping(isTyping);
      debugPrint('👀 Other user ($otherUserId) is typing: $isTyping');
    });
  }

  // Improved message sending logic with better handling for all message types
  Future<void> sendMessage(
    String userId,
    String chatRoomId,
    MessageModel message,
  ) async {
    MessageModel messageToSend;
    String? moderationResult;

    await _missionEventHandler.trackMissionProgress(
      category: "chat",
      type: "action",
      actionCount: 1,
    );

    // Determine message type and handle accordingly
    if (message.tripJournals != null && message.tripJournals!.isNotEmpty) {
      moderationResult = 'SAFE';

      messageToSend = MessageModel(
        messageId: message.messageId,
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        timestamp: message.timestamp,
        moderationStatus: moderationResult,
        tripJournals: message.tripJournals,
      );
    } else if (message.text != null && message.text!.isNotEmpty) {
      moderationResult = await _moderationService.checkContentLevel(
        message.text!,
      );

      messageToSend = MessageModel(
        messageId: message.messageId,
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        timestamp: message.timestamp,
        moderationStatus: moderationResult,
        tripJournals: message.tripJournals,
      );

      // Show appropriate error messages based on moderation result
      switch (moderationResult) {
        case 'WARNING':
          chatState.setErrorMessage(
            "⚠️ Warning: Your message contains sensitive content",
          );
          break;
        case 'UNSAFE':
          chatState.setErrorMessage(
            "🚫 Message blocked: Inappropriate content detected",
          );
          if (chatState.unsafeMessageCount >= 3) {
            throw Exception("BANNED");
          }
          break;
      }
    } else if ((message.musicUrl != null && message.musicUrl!.isNotEmpty) ||
        (message.stickerUrl != null && message.stickerUrl!.isNotEmpty)) {
      moderationResult = 'SAFE';
      messageToSend = MessageModel(
        messageId: message.messageId,
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        timestamp: message.timestamp,
        moderationStatus: moderationResult,
        tripJournals: message.tripJournals,
      );
    } else {
      // Invalid message with no content
      debugPrint("❌ Invalid message, no content to send");
      return;
    }

    // Send message via WebSocket

    chatState.incrementMessageCount(moderationResult ?? 'SAFE');
    await _chatService.sendMessage(userId, chatRoomId, messageToSend);

    // Directly add the message to the state instead of waiting for WebSocket response
    if (!chatState.messages.any(
      (m) => m.messageId == messageToSend.messageId,
    )) {
      chatState.addMessage(messageToSend);
    }
  }

  Future<void> updateTyping(
    String chatRoomId,
    String userId,
    bool isTyping,
  ) async {
    await _chatService.updateTypingStatus(chatRoomId, userId, isTyping);
  }

  Future<void> reportUser(String reporterId, String reportedId) async {
    await _chatService.reportUser(reporterId, reportedId);
  }

  Future<void> closeChatRoom(String chatRoomId) async {
    await _chatService.closeChatRoom(chatRoomId);
    // Set partnerLeft to true to ensure both users exit
    chatState.setPartnerLeft(true);
  }

  void setOtherUserId(String userId) {
    chatState.setOtherUserId(userId);
  }

  void setStickers(List<String> stickers) {
    chatState.setStickers(stickers);
  }

  void clearChatState() {
    chatState.clear();
  }

  Future<void> fetchChatPartner(String chatRoomId, String currentUserId) async {
    final partnerData = await _chatService.fetchChatPartner(
      chatRoomId,
      currentUserId,
    );
    if (partnerData != null) {
      final partnerId = partnerData['partnerId'] as String;
      final avatarImg = partnerData['avatarImg'] as String?;

      setOtherUserId(partnerId);

      // Set the other user's avatar
      if (avatarImg != null && avatarImg.isNotEmpty) {
        chatState.setOtherUserAvatarImg(avatarImg);
      }
    }
  }

  Future<void> handleExit(String chatRoomId, String currentUserId) async {
    final users = await _chatService.getChatUsers(chatRoomId);
    users.remove(currentUserId);

    _chatService.closeConnection();

    // Always close the chat room regardless of remaining users
    await closeChatRoom(chatRoomId);

    clearChatState();
  }

  Future<void> saveChatSummary(String currentUserId, String chatRoomId) async {
    try {
      final userSummary = {
        'userId': currentUserId,
        'safeCount': chatState.safeMessageCount,
        'warningCount': chatState.warningMessageCount,
        'unsafeCount': chatState.unsafeMessageCount,
        'totalMessages':
            chatState.messages.where((m) => m.senderId == currentUserId).length,
        'duration':
            DateTime.now()
                .difference(
                  chatState.messages.isNotEmpty
                      ? chatState.messages.first.timestamp
                      : DateTime.now(),
                )
                .inMinutes,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _chatService.saveChatSummary(chatRoomId, userSummary);
    } catch (e) {
      print("❌ Error saving chat summary: $e");
      // Still continue with exit flow
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserTripJournals(
    String userId,
  ) async {
    try {
      return await _tripJournalService.fetchUserTripJournals(userId);
    } catch (e) {
      print('Error in chat data binding - fetchUserTripJournals: $e');
      return [];
    }
  }

  // UI State Management Methods

  void setCurrentUserId(String userId) {
    chatState.setCurrentUserId(userId);
  }

  void setBanned(bool banned) {
    chatState.setBanned(banned);
  }

  void setPartnerLeft(bool left) {
    chatState.setPartnerLeft(left);
  }

  void setInactive(bool inactive) {
    chatState.setInactive(inactive);
  }

  void setCountdownWarningVisible(bool visible) {
    chatState.setCountdownWarningVisible(visible);
  }

  void setSummaryBeingShown(bool shown) {
    chatState.setSummaryBeingShown(shown);
  }

  void setSummaryCountdownSeconds(int seconds) {
    chatState.setSummaryCountdownSeconds(seconds);
  }

  void setSummaryTimerActive(bool active) {
    chatState.setSummaryTimerActive(active);
  }

  void markSummaryShown() {
    chatState.markSummaryShown();
  }

  void setDrawerVisible(bool visible) {
    chatState.setDrawerVisible(visible);
  }

  void setShowStickers(bool show) {
    chatState.setShowStickers(show);
  }

  void setShowFlowerAnimation(bool show) {
    chatState.setShowFlowerAnimation(show);
  }

  void setMusicPlaying(bool isPlaying) {
    chatState.setMusicPlaying(isPlaying);
  }

  void setCountdownSeconds(int seconds) {
    chatState.setCountdownSeconds(seconds);
  }

  // Method to send flower and update UI state
  Future<int> sendFlower(
    String userId,
    String chatRoomId,
    BuildContext context,
  ) async {
    final updatedCount = await _rewardService.sendFlower(
      userId,
      chatRoomId,
      context,
    );

    if (updatedCount >= 0) {
      // Show animation for 2 seconds
      setShowFlowerAnimation(true);
      Future.delayed(const Duration(seconds: 2), () {
        setShowFlowerAnimation(false);
      });
    }

    return updatedCount;
  }

  // Listen to flower events from the recipient
  StreamSubscription<QuerySnapshot> listenForFlowerEvents(
    String chatRoomId,
    void Function(QuerySnapshot) handleEvent,
  ) {
    return _rewardService.listenToFlowerEvents(chatRoomId).listen(handleEvent);
  }

  void setErrorMessage(String? message) {
    chatState.setErrorMessage(message);
  }

  void setUserTripJournals(List<Map<String, dynamic>> journals) {
    chatState.userTripJournals = journals;
  }

  void setIsLoadingTripJournals(bool loading) {
    chatState.isLoadingTripJournals = loading;
  }
}
