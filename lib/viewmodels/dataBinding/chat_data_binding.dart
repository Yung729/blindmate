import 'package:blindmate/models/api/giphy_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/chat_service.dart';
import '../../models/dataModels/message_model.dart';
import '../state/chat_state.dart';

class ChatDataBinding {
  final ChatService _chatService = ChatService();
  final GiphyService _giphyService = GiphyService();
  final ChatState chatState;

  ChatDataBinding({required this.chatState});

  void initialize(String chatRoomId) {
    _chatService.connectWebSocket(chatRoomId);

    _chatService.getMessages().listen((messages) {
      chatState.setMessages(messages);
    });

    _chatService.listenForChatUpdates(chatRoomId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data['closed'] == true) {
          chatState.setPartnerLeft(true);
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

  Future<void> sendMessage(String userId, String chatRoomId, MessageModel message) async {
    await _chatService.sendMessage(userId, chatRoomId, message);
  }

  Future<void> updateTyping(String chatRoomId, String userId, bool isTyping) async {
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
    final partnerId = await _chatService.fetchChatPartner(chatRoomId, currentUserId);
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
      await _chatService.markChatRoomClosed(chatRoomId);
    }

    clearChatState();
  }
}
