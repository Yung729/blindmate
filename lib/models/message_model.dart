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

  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      senderId: data['senderId'] ?? 'Unknown',
      text: data['text'],
      stickerUrl: data['stickerUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      if (text != null) 'text': text,
      if (stickerUrl != null) 'stickerUrl': stickerUrl, // ✅ Store stickers correctly
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
