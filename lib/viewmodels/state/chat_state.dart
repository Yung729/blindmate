import 'package:flutter/material.dart';
import '../../models/dataModels/message_model.dart';

class ChatState extends ChangeNotifier {
  bool isOtherUserTyping = false;
  bool partnerLeft = false;
  bool isTyping = false;
  bool isChatOpen = true;
  List<MessageModel> messages = [];
  String? otherUserId;
  List<String> stickerList = [];

  void updateTyping(bool isTyping) {
    this.isTyping = isTyping;
    notifyListeners();
  }

  void setOtherUserTyping(bool typing) {
    isOtherUserTyping = typing;
    notifyListeners();
  }

  void setPartnerLeft(bool left) {
    partnerLeft = left;
    notifyListeners();
  }

  void setMessages(List<MessageModel> newMessages) {
    messages = newMessages;
    notifyListeners();
  }

  void addMessage(MessageModel message) {
    messages.insert(0, message);
    notifyListeners();
  }

  void setOtherUserId(String userId) {
    otherUserId = userId;
    notifyListeners();
  }

  void setStickers(List<String> stickers) {
    stickerList = stickers;
    notifyListeners();
  }

  void clear() {
    messages.clear();
    stickerList.clear();
    isOtherUserTyping = false;
    otherUserId = null;
    partnerLeft = false;
    notifyListeners();
  }
}
