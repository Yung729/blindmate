import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId; // Unique ID for each message
  final String senderId;
  final String? text;
  final String? stickerUrl;
  final String? musicUrl;
  final String? musicTitle;
  final List<Map<String, dynamic>>? tripJournals;
  final DateTime timestamp;
  final String? moderationStatus;

  // Generate a random unique ID
  static String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(90000000) + 10000000;
    return '$timestamp-$random';
  }

  MessageModel({
    String? messageId,
    required this.senderId,
    this.text,
    this.stickerUrl,
    this.musicUrl,
    this.musicTitle,
    this.tripJournals,
    required this.timestamp,
    this.moderationStatus,
  }) : messageId = messageId ?? _generateUniqueId();

  /// 🔹 Convert Firestore Map to `MessageModel`
  factory MessageModel.fromMap(Map<String, dynamic> data) {
    List<Map<String, dynamic>>? journals;
    if (data['tripJournals'] != null) {
      journals = List<Map<String, dynamic>>.from(data['tripJournals']);
      print("🧳 Parsed ${journals.length} trip journals from Firestore");
    }

    return MessageModel(
      messageId: data['messageId'],
      senderId: data['senderId'] ?? 'Unknown',
      text: data['text'],
      stickerUrl: data['stickerUrl'],
      musicUrl: data['musicUrl'],
      musicTitle: data['musicTitle'],
      tripJournals: journals,
      timestamp:
          (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
      moderationStatus: data['moderationStatus'] ?? 'SAFE',
    );
  }

  /// 🔹 Convert WebSocket JSON data to `MessageModel`
  factory MessageModel.fromWebSocket(Map<String, dynamic> data) {
    print("PARSING WebSocket message: $data");

    List<Map<String, dynamic>>? journals;
    if (data['tripJournals'] != null) {
      try {
        journals = List<Map<String, dynamic>>.from(data['tripJournals']);
        print("🧳 Parsed ${journals.length} trip journals from WebSocket");
      } catch (e) {
        print("❌ Error parsing tripJournals: $e");
      }
    }

    return MessageModel(
      messageId:
          data['messageId'], // Will use provided ID or generate a new one if null
      senderId: data['senderId'] ?? 'Unknown',
      text: data['text'],
      stickerUrl: data['stickerUrl'],
      musicUrl: data['musicUrl'],
      musicTitle: data['musicTitle'],
      tripJournals: journals,
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      moderationStatus: data['moderationStatus'] ?? 'SAFE',
    );
  }

  /// 🔹 Convert to Firestore-friendly Map
  Map<String, dynamic> toMapForFirestore() {
    final Map<String, dynamic> result = {
      'messageId': messageId, // Include the sequential message ID
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'moderationStatus': moderationStatus ?? 'SAFE',
    };

    // Only add non-null fields
    if (text != null) result['text'] = text;
    if (stickerUrl != null) result['stickerUrl'] = stickerUrl;
    if (musicUrl != null) result['musicUrl'] = musicUrl;
    if (musicTitle != null) result['musicTitle'] = musicTitle;

    // Special handling for tripJournals
    if (tripJournals != null && tripJournals!.isNotEmpty) {
      result['tripJournals'] = tripJournals;
      print("🧳 Added tripJournals to Firestore map: $tripJournals");
    }

    return result;
  }

  /// 🔹 Convert to WebSocket-friendly Map (JSON)
  Map<String, dynamic> toMapForWebSocket() {
    return {
      'type': 'message', // Required for WebSocket messages
      'messageId': messageId, // Include the sequential message ID
      'senderId': senderId,
      'text': text,
      'stickerUrl': stickerUrl,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'tripJournals': tripJournals,
      'timestamp': timestamp.toIso8601String(),
      if (moderationStatus != null) 'moderationStatus': moderationStatus,
    };
  }
}
