import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String? text;
  final String? stickerUrl;
  final DateTime timestamp;

  MessageModel({
    required this.senderId,
    this.text,
    this.stickerUrl,
    required this.timestamp,
  });

  /// 🔹 Convert Firestore Map to `MessageModel`
  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? 'Unknown',
      text: data['text'],
      stickerUrl: data['stickerUrl'],
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// 🔹 Convert WebSocket JSON data to `MessageModel`
  factory MessageModel.fromWebSocket(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? 'Unknown',
      text: data['text'],
      stickerUrl: data['stickerUrl'],
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  /// 🔹 Convert to Firestore-friendly Map
  Map<String, dynamic> toMapForFirestore() {
    return {
      'senderId': senderId,
      if (text != null) 'text': text,
      if (stickerUrl != null) 'stickerUrl': stickerUrl,
      'timestamp': FieldValue.serverTimestamp(), // Firestore timestamp
    };
  }

  /// 🔹 Convert to WebSocket-friendly Map (JSON)
  Map<String, dynamic> toMapForWebSocket() {
    return {
      'type': 'message', // Required for WebSocket messages
      'senderId': senderId,
      'text': text,
      'stickerUrl': stickerUrl,
      'timestamp': timestamp.toIso8601String(), // WebSocket requires ISO string
    };
  }
}
