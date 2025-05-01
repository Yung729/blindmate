import 'package:blindmate/models/api/giphy_service.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
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
  final ChatState chatState;

  ChatDataBinding({required this.chatState});

  void initialize(String chatRoomId, String userId) {
    // Initialize network connections first
    _chatService.connectWebSocket(chatRoomId, userId);

    // Set up listeners with optimized state updates
    _chatService.getMessages().listen((message) {
      print("📩 RECEIVED message: $message");
      if (message.tripJournals != null) {
        print("📩 RECEIVED tripJournals: ${message.tripJournals}");
      }

      // Use microtask for better performance while avoiding setState errors
      Future.microtask(() {
        // Only add if not already in the list
        if (chatState.messages.isEmpty ||
            !chatState.messages.any((m) => m.timestamp == message.timestamp)) {
          chatState.addMessage(message);
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
    try {
      chatState.setIsLoadingStickers(true);

      // Check if the sticker search query is positive using Gemini
      final isPositive = await _moderationService.isStickerSearchPositive(
        query,
      );

      if (isPositive) {
        // Fetch stickers with the query if it's positive
        List<String> stickers = await _giphyService.fetchStickers(query);
        setStickers(stickers);
        debugPrint("🔍 Positive sticker search: '$query'");
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

  // FIX: Improved message sending logic with better handling for tripJournals
  Future<void> sendMessage(
    String userId,
    String chatRoomId,
    MessageModel message,
  ) async {
    // Check if this is a trip journal message
    if (message.tripJournals != null && message.tripJournals!.isNotEmpty) {
      debugPrint("🧳 Sending trip journal message with ${message.tripJournals!.length} entries");
      
      // For trip journals, mark as SAFE by default and send immediately
      final tripJournalMessage = MessageModel(
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        timestamp: message.timestamp,
        moderationStatus: 'SAFE',
        tripJournals: message.tripJournals,
      );
      
      await _chatService.sendMessage(userId, chatRoomId, tripJournalMessage);
      return;
    }
    
    // Handle regular text messages
    if (message.text != null && message.text!.isNotEmpty) {
      final moderationResult = await _moderationService.checkContentLevel(
        message.text!,
      );

      final moderatedMessage = MessageModel(
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        timestamp: message.timestamp,
        moderationStatus: moderationResult, // Add moderation status
        tripJournals: message.tripJournals,
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
          break;
          
        default:
          throw Exception("Message moderation failed");
      }
    } else if (
      (message.musicUrl != null && message.musicUrl!.isNotEmpty) ||
      (message.stickerUrl != null && message.stickerUrl!.isNotEmpty)
    ) {
      // For stickers or music, mark as SAFE by default
      final safeMessage = MessageModel(
        senderId: message.senderId,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        timestamp: message.timestamp,
        moderationStatus: 'SAFE',
        tripJournals: message.tripJournals,
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

  Future<List<Map<String, dynamic>>> fetchUserTripJournals(String userId) async {
    try {
      return await _tripJournalService.fetchUserTripJournals(userId);
    } catch (e) {
      print('Error in chat data binding - fetchUserTripJournals: $e');
      return [];
    }
  }
}