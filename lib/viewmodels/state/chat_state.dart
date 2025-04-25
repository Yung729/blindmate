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
  String? errorMessage;
  int unsafeMessageCount = 0;
  int safeMessageCount = 0;
  int warningMessageCount = 0;
  bool _hasSummaryShown = false;
  bool isInactive = false;
  bool isBanned = false;
  bool _reportedUser = false;
  bool _showFlowerAnimation = false;
  bool _isMusicPlaying = false;

  bool get reportedUser => _reportedUser;
  
  bool get isMusicPlaying => _isMusicPlaying;
  
  void setMusicPlaying(bool isPlaying) {
    if (_isMusicPlaying != isPlaying) {
      _isMusicPlaying = isPlaying;
      notifyListeners();
    }
  }

  void setReportedUser(bool reported) {
    if (_reportedUser != reported) {
      _reportedUser = reported;
      notifyListeners();
    }
  }

  void setBanned(bool banned) {
    if (isBanned != banned) {
      isBanned = banned;
      notifyListeners();
    }
  }

  bool get hasSummaryShown => _hasSummaryShown;

  void markSummaryShown() {
    _hasSummaryShown = true;
    notifyListeners();
  }

  void setInactive(bool inactive) {
    if (isInactive != inactive) {
      isInactive = inactive;
      notifyListeners();
    }
  }

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

  void setErrorMessage(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  void incrementMessageCount(String moderationStatus) {
    switch (moderationStatus) {
      case 'SAFE':
        safeMessageCount++;
        break;
      case 'WARNING':
        warningMessageCount++;
        break;
      case 'UNSAFE':
        unsafeMessageCount++;
        break;
    }
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
    safeMessageCount = 0;
    warningMessageCount = 0;
    unsafeMessageCount = 0;
    errorMessage = null;
    _hasSummaryShown = false;
    isInactive = false;
    isBanned = false;
    _reportedUser = false;
    isChatOpen = true; // Reset this flag
    notifyListeners();
  }

  bool get showFlowerAnimation => _showFlowerAnimation;

  void setShowFlowerAnimation(bool show) {
    _showFlowerAnimation = show;
    notifyListeners();
  }
}
