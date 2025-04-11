import 'package:flutter/material.dart';
import '../../models/dataModels/message_model.dart';

class ChatState extends ChangeNotifier {
  
  List<MessageModel> messages = [];
  String? otherUserId;
  bool isOtherUserTyping = false;
  bool partnerLeft = false;
  List<String> stickerList = [];
  bool isLoadingStickers = false;
  bool isTyping = false;
  bool isChatOpen = true;
  
  void updateTyping(bool typing) {
    if (isTyping != typing) {
        isTyping = typing;
        notifyListeners();
    }
  }

  void setOtherUserTyping(bool typing) {
    isOtherUserTyping = typing;
    notifyListeners();
  }

  void setPartnerLeft(bool left) {
    if (partnerLeft != left) {
      partnerLeft = left;
      notifyListeners();
    }
  }

  void setMessages(List<MessageModel> newMessages) {
    messages = newMessages;
    notifyListeners();
  }

  void addMessage(MessageModel message) {
    messages.insert(0, message);
    notifyListeners();
  }

  void setOtherUserId(String? userId) {
    otherUserId = userId;
    notifyListeners();
  }

  void setStickers(List<String> stickers) {
    stickerList = stickers;
    notifyListeners();
  }

void setIsLoadingStickers(bool loading) {
      isLoadingStickers = loading;
      notifyListeners();
  }

  void clear() {
    messages.clear();
    stickerList.clear();
    isOtherUserTyping = false;
    otherUserId = null;
    partnerLeft = false;
    isTyping = false;
    isLoadingStickers = false;
    notifyListeners();
  }
}
