import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Find a match ensuring different emotional statuses
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
                  UserModel.fromMap(doc.data(), doc.id),
            )
            .where(
              (matchedUser) =>
                  !reportedByMe.contains(matchedUser.userId) &&
                  !reportedMe.contains(matchedUser.userId) &&
                  _isValidMatch(user.emotionalStatus, matchedUser.emotionalStatus),
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

  // 🔹 Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({'status': status});
  }

  // 🔹 Start Searching for a Match
  Future<String?> startMatching(UserModel user) async {
    await updateUserStatus(user.userId, 'waiting');
    return await findMatch(user);
  }

  // 🔹 Listen for Real-Time Match Updates
  void listenForMatch(String userId, Function(String) onMatchFound) {
    _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .where('closed', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            String chatRoomId = querySnapshot.docs.first.id;
            onMatchFound(chatRoomId);
          }
        });
  }

  // 🔹 Check if the match is valid based on emotional status
  bool _isValidMatch(String userEmotionalStatus, String matchedUserEmotionalStatus) {
    const badEmotions = ['sad', 'fear', 'disgust', 'anger'];
    bool isUserBadEmotion = badEmotions.contains(userEmotionalStatus);
    bool isMatchedUserBadEmotion = badEmotions.contains(matchedUserEmotionalStatus);

    // Avoid matching two users with bad emotional statuses together
    if (isUserBadEmotion && isMatchedUserBadEmotion) {
      return false;
    }

    return true;
  }
}