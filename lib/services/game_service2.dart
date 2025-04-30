import 'package:cloud_firestore/cloud_firestore.dart';

class GameService2 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGame(String chatRoomId, Map<String, dynamic> gameData) async {
    await _firestore.collection('games2').doc(chatRoomId).set(gameData);
  }

  Future<void> updateGame(String chatRoomId, Map<String, dynamic> gameData) async {
    await _firestore.collection('games2').doc(chatRoomId).update(gameData);
  }

  Stream<DocumentSnapshot> listenToGame(String chatRoomId) {
    return _firestore.collection('games2').doc(chatRoomId).snapshots();
  }

  Future<Map<String, dynamic>?> getGame(String chatRoomId) async {
    final doc = await _firestore.collection('games2').doc(chatRoomId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> updateBoard(String chatRoomId, List<String> board) async {
    await _firestore.collection('games2').doc(chatRoomId).update({
      'board': board,
    });
  }

  Future<void> updateRoles(String chatRoomId, Map<String, String> roles) async {
    await _firestore.collection('games2').doc(chatRoomId).update({
      'roles': roles,
    });
  }

  Future<void> setWinner(String chatRoomId, String winnerId) async {
    await _firestore.collection('games2').doc(chatRoomId).update({
      'winner': winnerId,
    });
  }

  Future<void> clearGame(String chatRoomId) async {
    await _firestore.collection('games2').doc(chatRoomId).delete();
  }
} 