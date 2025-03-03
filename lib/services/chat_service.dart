import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({'status': status});
  }

  // 🔹 Find a match ensuring different mental health levels
  Future<String?> findMatch(UserModel user) async {
    print("🔍 Searching for a match for user: ${user.userId}");

    // Fetch list of users **reported by the current user**
    final reportedByMeSnapshot =
        await _firestore
            .collection('reports')
            .where('reporterId', isEqualTo: user.userId)
            .get();

    List<String> reportedByMe =
        reportedByMeSnapshot.docs
            .map((doc) => doc['reportedId'] as String)
            .toList();

    print("🚫 Users I reported: ${reportedByMe.length}");

    // Fetch list of users **who reported the current user**
    final reportedMeSnapshot =
        await _firestore
            .collection('reports')
            .where('reportedId', isEqualTo: user.userId)
            .get();

    List<String> reportedMe =
        reportedMeSnapshot.docs
            .map((doc) => doc['reporterId'] as String)
            .toList();

    print("🚫 Users who reported me: ${reportedMe.length}");

    final querySnapshot =
        await _firestore
            .collection('users')
            .where('status', isEqualTo: 'waiting')
            .where('online', isEqualTo: true)
            .get();

    print("✅ Found ${querySnapshot.docs.length} potential matches");

    List<UserModel> potentialMatches =
        querySnapshot.docs
            .where((doc) => doc.id != user.userId)
            .map(
              (doc) =>
                  UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .where(
              (matchedUser) =>
                  matchedUser.mentalHealthLevel != user.mentalHealthLevel &&
                  !reportedByMe.contains(matchedUser.userId) &&
                  !reportedMe.contains(matchedUser.userId),
            )
            .toList();

    print("🎯 Filtered down to ${potentialMatches.length} valid matches");

    if (potentialMatches.isNotEmpty) {
      Random random = Random();
      UserModel matchedUser =
          potentialMatches[random.nextInt(potentialMatches.length)];

      String chatRoomId = _firestore.collection('chats').doc().id;
      print(
        "🚀 Creating chat room: $chatRoomId between ${user.userId} and ${matchedUser.userId}",
      );

      // **🔹 Immediately update both users to "in_chat" before creating chat room**
      await updateUserStatus(user.userId, 'in_chat');
      await updateUserStatus(matchedUser.userId, 'in_chat');

      // **🔹 Create the chat room**
      await _firestore.collection('chats').doc(chatRoomId).set({
        'users': [user.userId, matchedUser.userId],
        'createdAt': FieldValue.serverTimestamp(),
        'closed': false,
      });

      print("✅ Chat room $chatRoomId successfully created");
      return chatRoomId;
    }

    print("❌ No match found");
    return null;
  }

  // 🔹 Listen for chat updates (when chat is closed)
  Stream<DocumentSnapshot> listenForChatUpdates(String chatRoomId) {
    return _firestore.collection('chats').doc(chatRoomId).snapshots();
  }

  // 🔹 Send a message
  Future<void> sendMessage(String chatRoomId, MessageModel message) async {
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());
  }

  Future<void> updateTypingStatus(
    String chatRoomId,
    String userId,
    bool isTyping,
  ) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).update(
      {'typing.$userId': isTyping},
    );
  }

  // 🔹 Get chat messages in real time
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList();
        });
  }

  // 🔹 Close the chat room and reset users' status
  Future<void> closeChatRoom(String chatRoomId, List<String> users) async {
    await _firestore.collection('chats').doc(chatRoomId).update({
      'closed': true,
    });

    // 🔹 Ensure Firestore updates properly
    await Future.delayed(const Duration(milliseconds: 500));

    for (String userId in users) {
      await updateUserStatus(userId, 'available');
    }
  }

  Future<void> reportUser(String reporterId, String reportedId) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
