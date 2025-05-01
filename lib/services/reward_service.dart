import 'package:blindmate/models/dataModels/rewards_model.dart';
import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/user_reward_model.dart';
import 'package:blindmate/views/screens/redeem_reward_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../viewmodels/state/auth_state.dart';
import '../services/level_progression_service.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, DateTime> _lastFlowerSentTime = {}; // Track last sent time per user
  static const Duration _flowerCooldown = Duration(seconds: 3); // Cooldown period
  final LevelProgressionService _levelService = LevelProgressionService();

  // Fetch the available rewards from the Firestore collection
  Future<List<RewardModel>> getAvailableRewards() async {
    try {
      final rewardsSnapshot = await _firestore.collection('reward').get();
      return rewardsSnapshot.docs
          .map((doc) => RewardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch rewards: $e");
    }
  }

  // Fetch user rewards (redeemed rewards)
  Future<UserReward?> fetchUserRewards(String userId) async {
    try {
      final userRewardDoc =
          await _firestore.collection('user_reward').doc(userId).get();
      if (userRewardDoc.exists) {
        print('Fetched user reward doc: ${userRewardDoc.data()}');
        return UserReward.fromFirestore(userRewardDoc);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to fetch user rewards: $e");
    }
  }

  Future<int> redeemReward(
  String userId,
  int fragmentCost,
  String rewardId,
  [BuildContext? context]
) async {
  try {
    // Fetch reward info to check type
    final rewardDoc = await _firestore.collection('reward').doc(rewardId).get();
    final reward = RewardModel.fromFirestore(rewardDoc);

    final userRef = _firestore.collection('users').doc(userId);

    // 🔻 Deduct fragments no matter what
    await userRef.update({
      'fragmentNumber': FieldValue.increment(-fragmentCost),
    });

    // 🔻 If reward is "flower", increment flower count
    if (reward.rewardTitle?.toLowerCase() == 'flower') {
      await userRef.update({
        'flower': FieldValue.increment(1),
      });
      
      // Get the updated flower count to update the AuthState
      final updatedUserDoc = await userRef.get();
      final updatedFlowerCount = updatedUserDoc.data()?['flower'] ?? 0;
      
      // Update AuthState if context is provided
      if (context != null) {
        final authState = Provider.of<AuthState>(context, listen: false);
        if (authState.currentUser != null) {
          authState.currentUser!.flower = updatedFlowerCount;
          authState.notifyListeners();
        }
      }
    } else {
      // 🔻 Otherwise, update redeemed reward list
      final userReward = await fetchUserRewards(userId);
      List<dynamic> redeemedRewards = userReward?.redeemedRewards ?? [];
      redeemedRewards.add(rewardId);

      await _firestore.collection('user_reward').doc(userId).set({
        'userId': userId,
        'redeemedReward': redeemedRewards,
      }, SetOptions(merge: true));
    }

    // 🔻 Return updated fragment number
    final updatedUserDoc = await userRef.get();
    final updatedFragmentNumber =
        updatedUserDoc.data()?['fragmentNumber'] ?? 0;

    return updatedFragmentNumber;
  } catch (e) {
    throw Exception("Failed to redeem reward: $e");
  }
}

  Future<int> sendFlower(String userId, String chatRoomId, BuildContext context) async {
    // Check cooldown
    final lastSent = _lastFlowerSentTime[userId];
    final now = DateTime.now();
    if (lastSent != null && now.difference(lastSent) < _flowerCooldown) {
      return -1; // Return -1 to indicate cooldown
    }

    final userRef = _firestore.collection('users').doc(userId);
    final snapshot = await userRef.get();
    final currentFlower = snapshot.data()?['flower'] ?? 0;

    if (currentFlower > 0) {
      // Update flower count in Firestore
      await userRef.update({'flower': currentFlower - 1});

      // Update auth state
      final authState = Provider.of<AuthState>(context, listen: false);
      if (authState.currentUser != null) {
        authState.currentUser!.flower = currentFlower - 1;
        authState.notifyListeners();
      }
      
      // Get the recipient's user ID (the chat partner)
      final chatDoc = await _firestore.collection('chats').doc(chatRoomId).get();
      final chatData = chatDoc.data();
      if (chatData != null && chatData.containsKey('users')) {
        final List<String> users = List<String>.from(chatData['users'] ?? []);
        // Find the other user (not the sender)
        final String? recipientId = users.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );
        
          try {
            await _levelService.incrementProgressionWithFlower(recipientId!);
            print('Updated level progression for user $recipientId');
          } catch (e) {
            print('Error updating level progression: $e');
          }
        
      }

      // Send flower animation event to chat room
      await _firestore.collection('chats').doc(chatRoomId).collection('events').add({
        'type': 'flower',
        'senderId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      


      // Update cooldown tracker
      _lastFlowerSentTime[userId] = now;

      return currentFlower - 1;
    } else {
      return 0;
    }
  }

  Stream<QuerySnapshot> listenToFlowerEvents(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('events')
        .where('type', isEqualTo: 'flower')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }
}
