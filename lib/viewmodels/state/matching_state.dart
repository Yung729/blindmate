import 'package:flutter/material.dart';

class MatchingState with ChangeNotifier {
  String userStatus = 'available';
  String? chatRoomId;

  void updateStatus(String newStatus) {
    userStatus = newStatus;
    notifyListeners();
  }

  void setChatRoomId(String? newChatRoomId) {
    chatRoomId = newChatRoomId;
    notifyListeners();
  }

  void clear() {
    userStatus = 'available';
    chatRoomId = null;
    notifyListeners();
  }
}
