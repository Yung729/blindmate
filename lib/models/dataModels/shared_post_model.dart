import 'package:cloud_firestore/cloud_firestore.dart';

class SharedPostModel {
  final String id;
  final String userId;
  final String content;
  final String? musicUrl;
  final String visibility;
  final DateTime timestamp;

  SharedPostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.musicUrl,
    required this.visibility,
    required this.timestamp,
  });

  factory SharedPostModel.fromMap(Map<String, dynamic> map, String docId) {
    return SharedPostModel(
      id: docId,
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      musicUrl: map['musicUrl'],
      visibility: map['visibility'] ?? 'public',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'musicUrl': musicUrl,
      'visibility': visibility,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}