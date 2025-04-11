import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';
import '../state/matching_state.dart';
import '../dataBinding/matching_data_binding.dart';
import '../../views/screens/chat_screen.dart';

class MatchingEventHandler {
  final MatchingState matchingState;
  final MatchingDataBinding dataBinding;

  MatchingEventHandler({
    required this.matchingState,
    required this.dataBinding,
  });

  Future<void> init(String userId) async {
    await dataBinding.initialize(userId);
  }

  Future<void> startMatching(UserModel user) async {
    await dataBinding.startMatching(user);
  }

  Future<void> cancelMatching(String userId) async {
    await dataBinding.cancelMatching(userId);
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await dataBinding.updateUserStatus(userId, status);
  }

  void navigateToChat(BuildContext context, String chatRoomId, String currentUserId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatRoomId,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}