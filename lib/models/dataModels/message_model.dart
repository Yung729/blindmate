import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String? text;
  final String? stickerUrl;
  final String? musicUrl;
  final String? musicTitle;
  final DateTime timestamp;
  final String? moderationStatus;

  MessageModel({
    required this.senderId,
    this.text,
    this.stickerUrl,
    this.musicUrl,
    this.musicTitle,
    required this.timestamp,
    this.moderationStatus,
  });

  /// 🔹 Convert Firestore Map to `MessageModel`
  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? 'Unknown',
      text: data['text'],
      stickerUrl: data['stickerUrl'],
      musicUrl: data['musicUrl'],
      musicTitle: data['musicTitle'],
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      moderationStatus: data['moderationStatus'] ?? 'SAFE',
    );
  }

  /// 🔹 Convert WebSocket JSON data to `MessageModel`
  factory MessageModel.fromWebSocket(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? 'Unknown',
      text: data['text'],
      stickerUrl: data['stickerUrl'],
      musicUrl: data['musicUrl'],
      musicTitle: data['musicTitle'],
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      moderationStatus: data['moderationStatus'] ?? 'SAFE',
    );
  }

  /// 🔹 Convert to Firestore-friendly Map
  Map<String, dynamic> toMapForFirestore() {
    return {
      'senderId': senderId,
      if (text != null) 'text': text,
      if (stickerUrl != null) 'stickerUrl': stickerUrl,
      if (musicUrl != null) 'musicUrl': musicUrl,
      if (musicTitle != null) 'musicTitle': musicTitle,
      'timestamp': FieldValue.serverTimestamp(), 
      if (moderationStatus != null) 'moderationStatus': moderationStatus,
    };
  }

  /// 🔹 Convert to WebSocket-friendly Map (JSON)
  Map<String, dynamic> toMapForWebSocket() {
    return {
      'type': 'message', // Required for WebSocket messages
      'senderId': senderId,
      'text': text,
      'stickerUrl': stickerUrl,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'timestamp': timestamp.toIso8601String(), 
      if (moderationStatus != null) 'moderationStatus': moderationStatus,
    };
  }
}
