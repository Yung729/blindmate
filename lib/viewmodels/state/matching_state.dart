import 'package:flutter/material.dart';

class MatchingState with ChangeNotifier {
  String userStatus = 'available';
  String? chatRoomId;
  bool isSearching = false;

  void updateStatus(String newStatus) {
    userStatus = newStatus;
    notifyListeners();
  }

  void setChatRoomId(String? newChatRoomId) {
    chatRoomId = newChatRoomId;
    notifyListeners();
  }
  
  void setSearching(bool searching) {
    isSearching = searching;
    notifyListeners();
  }

  void clear() {
    userStatus = 'available';
    chatRoomId = null;
    isSearching = false;
    notifyListeners();
  }
}
