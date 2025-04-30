import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/game_model.dart';
import '../utils/game_utils.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Offset;

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createGame(GameModel game) async {
    await _firestore.collection('games').doc(game.chatRoomId).set(game.toMap());
  }

  Future<void> updateGame(GameModel game) async {
    await _firestore.collection('games').doc(game.chatRoomId).update(game.toMap());
  }

  Stream<DocumentSnapshot> listenToGame(String chatRoomId) {
    return _firestore.collection('games').doc(chatRoomId).snapshots();
  }

  Future<GameModel?> getGame(String chatRoomId) async {
    final doc = await _firestore.collection('games').doc(chatRoomId).get();
    if (!doc.exists) return null;
    return GameModel.fromMap(doc.data()!);
  }

  Future<void> updatePoints(String chatRoomId, List<Offset?> points) async {
  await _firestore.collection('games').doc(chatRoomId).update({
    'points': GameUtils.pointsToMap(points),
  });
}

  Future<void> updateRoles(String chatRoomId, Map<String, String> roles) async {
    await _firestore.collection('games').doc(chatRoomId).update({
      'roles': roles,
    });
  }

  Future<void> updateScores(String chatRoomId, Map<String, int> scores) async {
    await _firestore.collection('games').doc(chatRoomId).update({
      'scores': scores,
    });
  }

  Future<void> setWinner(String chatRoomId, String winnerId) async {
    await _firestore.collection('games').doc(chatRoomId).update({
      'winner': winnerId,
    });
  }

  Future<void> clearGame(String chatRoomId) async {
    await _firestore.collection('games').doc(chatRoomId).delete();
  }
} 