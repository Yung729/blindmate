import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/game_utils.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Offset;

class GameModel {
  final String chatRoomId;
  final String currentUserId;
  final String opponentId;
  final bool isDrawer;
  final String word;
  final List<Offset?> points;
  final Map<String, String> roles;
  final Map<String, int> scores;
  final String? winner;
  final DateTime timestamp;

  GameModel({
    required this.chatRoomId,
    required this.currentUserId,
    required this.opponentId,
    required this.isDrawer,
    required this.word,
    required this.points,
    required this.roles,
    required this.scores,
    this.winner,
    required this.timestamp,
  });

  factory GameModel.fromMap(Map<String, dynamic> data) {
    return GameModel(
      chatRoomId: data['chatRoomId'] ?? '',
      currentUserId: data['currentUserId'] ?? '',
      opponentId: data['opponentId'] ?? '',
      isDrawer: data['isDrawer'] ?? false,
      word: data['word'] ?? '',
      points: GameUtils.pointsFromMap(data['points'] as List?),
      roles: Map<String, String>.from(data['roles'] ?? {}),
      scores: Map<String, int>.from(data['scores'] ?? {}),
      winner: data['winner'],
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'currentUserId': currentUserId,
      'opponentId': opponentId,
      'isDrawer': isDrawer,
      'word': word,
      'points': GameUtils.pointsToMap(points),
      'roles': roles,
      'scores': scores,
      'winner': winner,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
} 