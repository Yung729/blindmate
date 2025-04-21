import 'package:blindmate/models/api/giphy_service.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../models/dataModels/message_model.dart';
import '../state/chat_state.dart';

class ChatDataBinding {
  final ChatService _chatService = ChatService();
  final GiphyService _giphyService = GiphyService();
  final GeminiModerationService _moderationService = GeminiModerationService();
  final ChatState chatState;

  ChatDataBinding({required this.chatState});

  void initialize(String chatRoomId) {
    // Initialize network connections first
    _chatService.connectWebSocket(chatRoomId);

    // Set up listeners with optimized state updates
    _chatService.getMessages().listen((messages) {
      // Use microtask for better performance while avoiding setState errors
      Future.microtask(() {
        chatState.setMessages(messages);
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
    try {
      chatState.setIsLoadingStickers(true);
      List<String> stickers = await _giphyService.fetchStickers(query);
      setStickers(stickers);
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

  Future<void> sendMessage(
    String userId,
    String chatRoomId,
    MessageModel message,
  ) async {
    if (message.text != null && message.text!.isNotEmpty) {
      final moderationResult = await _moderationService.checkContentLevel(
        message.text!,
      );

      final moderatedMessage = MessageModel(
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        timestamp: message.timestamp,
        moderationStatus: moderationResult, // Add moderation status
      );

      if (message.senderId == userId) {
        chatState.incrementMessageCount(moderationResult ?? "SAFE");
      }

      switch (moderationResult) {
        case 'SAFE':
          await _chatService.sendMessage(userId, chatRoomId, moderatedMessage);
          break;

        case 'WARNING':
          chatState.setErrorMessage(
            "⚠️ Warning: Your message contains sensitive content",
          );
          await _chatService.sendMessage(userId, chatRoomId, moderatedMessage);
          break;

        case 'UNSAFE':
          chatState.setErrorMessage(
            "🚫 Message blocked: Inappropriate content detected",
          );
          await _chatService.sendMessage(userId, chatRoomId, moderatedMessage);

          if (chatState.unsafeMessageCount >= 3) {
            throw Exception("BANNED");
          }

        default:
          throw Exception("Message moderation failed");
      }
    } else {
      // For stickers, mark as SAFE by default
      final safeMessage = MessageModel(
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        timestamp: message.timestamp,
        moderationStatus: 'SAFE',
      );
      await _chatService.sendMessage(userId, chatRoomId, safeMessage);
    }
  }

  Future<void> updateTyping(
    String chatRoomId,
    String userId,
    bool isTyping,
  ) async {
    await _chatService.updateTypingStatus(chatRoomId, userId, isTyping);
  }

  void closeConnection() {
    _chatService.closeConnection();
  }

  Future<void> reportUser(String reporterId, String reportedId) async {
    await _chatService.reportUser(reporterId, reportedId);
  }

  Future<void> closeChatRoom(String chatRoomId) async {
    await _chatService.closeChatRoom(chatRoomId);
  }

  void setOtherUserId(String userId) {
    chatState.setOtherUserId(userId);
  }

  void setStickers(List<String> stickers) {
    chatState.setStickers(stickers);
  }

  void addMessage(MessageModel message) {
    chatState.addMessage(message);
  }

  void clearChatState() {
    chatState.clear();
  }

  Future<void> fetchChatPartner(String chatRoomId, String currentUserId) async {
    final partnerId = await _chatService.fetchChatPartner(
      chatRoomId,
      currentUserId,
    );
    if (partnerId != null) {
      setOtherUserId(partnerId);
    }
  }

  Future<void> handleExit(String chatRoomId, String currentUserId) async {
    final users = await _chatService.getChatUsers(chatRoomId);
    users.remove(currentUserId);

    closeConnection();

    if (users.isEmpty) {
      await _chatService.closeChatRoom(chatRoomId);
    } else {
      await _chatService.closeChatRoom(chatRoomId);
    }

    clearChatState();
  }

  Future<String?> moderateContent(String message) async {
    return await _moderationService.checkContentLevel(message);
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
}
