import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? id;
  final String userId;
  final String userName;
  final String content;
  final String? musicUrl;
  final String? musicTitle;
  final DateTime timestamp;
  final String visibility;

  PostModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.content,
    this.musicUrl,
    this.musicTitle,
    required this.timestamp,
    required this.visibility,
  });

  // Convert the PostModel instance into a Map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'timestamp': FieldValue.serverTimestamp(),
      'visibility': visibility,
    };
  }

  // Create a PostModel instance from a Firestore document
  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      content: map['content'] ?? '',
      musicUrl: map['musicUrl'],
      musicTitle: map['musicTitle'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      visibility: map['visibility'] ?? 'public',
    );
  }
}
