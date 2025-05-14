import 'package:flutter/material.dart';
import '../../models/dataModels/message_model.dart';

class ChatState extends ChangeNotifier {
  // Message & Chat Data
  List<MessageModel> messages = [];
  String? otherUserId;
  String? currentUserId;
  String? otherUserAvatarImg;
  bool isOtherUserTyping = false;
  bool partnerLeft = false;
  List<String> stickerList = [];
  int unsafeMessageCount = 0;
  int safeMessageCount = 0;
  int warningMessageCount = 0;
  
  // Anti-spam properties
  final List<DateTime> _recentMessageTimestamps = [];
  final int _maxMessagesPerWindow = 5; // Allow 5 messages in the time window
  final int _timeWindowMs = 3000; // 3 second window for burst messages
  
  // UI States
  bool isDrawerVisible = false;
  bool showStickers = false;
  bool isCountdownWarningVisible = false;
  bool isSummaryBeingShown = false;
  bool isLoadingStickers = false;
  bool isTyping = false;
  bool isChatOpen = true;
  String? errorMessage;
  bool _hasSummaryShown = false;
  bool isInactive = false;
  bool isBanned = false;
  bool _reportedUser = false;
  bool _showFlowerAnimation = false;
  bool _isMusicPlaying = false;
  int _countdownSeconds = 0;
  bool _isSummaryTimerActive = false;
  int _summaryCountdownSeconds = 10; // 10 seconds countdown for summary dialog

  bool get reportedUser => _reportedUser;

  bool get isMusicPlaying => _isMusicPlaying;

  List<Map<String, dynamic>> _userTripJournals = [];
  bool _isLoadingTripJournals = false;

  // Setter methods for UI states
  void setDrawerVisible(bool visible) {
    isDrawerVisible = visible;
    notifyListeners();
  }

  void setShowStickers(bool show) {
    showStickers = show;
    notifyListeners();
  }

  void setCountdownWarningVisible(bool visible) {
    isCountdownWarningVisible = visible;
    notifyListeners();
  }

  void setSummaryBeingShown(bool shown) {
    isSummaryBeingShown = shown;
    notifyListeners();
  }

  // Getter and setter for userTripJournals
  List<Map<String, dynamic>> get userTripJournals => _userTripJournals;
  set userTripJournals(List<Map<String, dynamic>> value) {
    _userTripJournals = value;
    notifyListeners();
  }

  // Getter and setter for isLoadingTripJournals
  bool get isLoadingTripJournals => _isLoadingTripJournals;
  set isLoadingTripJournals(bool value) {
    _isLoadingTripJournals = value;
    notifyListeners();
  }

  // Add getter for countdown seconds
  int get countdownSeconds => _countdownSeconds;

  // Add setter for countdown seconds
  void setCountdownSeconds(int seconds) {
    if (_countdownSeconds != seconds) {
      _countdownSeconds = seconds;
      notifyListeners();
    }
  }

  void setMusicPlaying(bool isPlaying) {
    if (_isMusicPlaying != isPlaying) {
      _isMusicPlaying = isPlaying;
      notifyListeners();
    }
  }

  void setCurrentUserId(String userId) {
    if (currentUserId != userId) {
      currentUserId = userId;
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

  void setOtherUserAvatarImg(String? avatarImg) {
    otherUserAvatarImg = avatarImg;
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
    
  /// Check if the user is sending messages too quickly
  /// Returns a map with 'isSpam' boolean and 'reason' string if sending too fast
  Map<String, dynamic> checkMessageTiming() {
    final now = DateTime.now();
    final result = {'isSpam': false, 'reason': ''};
    
    // First, clean up old timestamps outside our window
    _recentMessageTimestamps.removeWhere((timestamp) => 
        now.difference(timestamp).inMilliseconds > _timeWindowMs);
    
    // Check if too many messages were sent in the time window
    if (_recentMessageTimestamps.length >= _maxMessagesPerWindow) {
      result['isSpam'] = true;
      result['reason'] = 'Please slow down. You can only send $_maxMessagesPerWindow messages every ${_timeWindowMs ~/ 1000} seconds.';
      return result;
    }
    
    // If we get here, the message is allowed
    _recentMessageTimestamps.add(now);
    return result;
  }

  void incrementMessageCount(String moderationStatus) {
    switch (moderationStatus) {
      case 'SAFE':
        safeMessageCount++;
        break;
      case 'WARNING':
      case 'SENSITIVE':
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
    otherUserAvatarImg = null;
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
    isChatOpen = true;
    _countdownSeconds = 0;
    _summaryCountdownSeconds = 10;
    _isSummaryTimerActive = false;
    isDrawerVisible = false;
    showStickers = false;
    isCountdownWarningVisible = false;
    isSummaryBeingShown = false;
    notifyListeners();
  }

  bool get showFlowerAnimation => _showFlowerAnimation;

  void setShowFlowerAnimation(bool show) {
    _showFlowerAnimation = show;
    notifyListeners();
  }

  // Add getter and setter for summary timer state
  bool get isSummaryTimerActive => _isSummaryTimerActive;
  
  void setSummaryTimerActive(bool isActive) {
    _isSummaryTimerActive = isActive;
    notifyListeners();
  }
  
  // Add getter and setter for summary countdown seconds
  int get summaryCountdownSeconds => _summaryCountdownSeconds;
  
  void setSummaryCountdownSeconds(int seconds) {
    _summaryCountdownSeconds = seconds;
    notifyListeners();
  }
}
