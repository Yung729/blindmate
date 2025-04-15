
import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { normal, tripJournal }

class PostModel {
  final String? id;
  final String userId;
  final String userName;
  final String content;
  final String? musicUrl;
  final String? musicTitle;
  final DateTime timestamp;
  String visibility; // Made non-final to allow modification

  // New fields for post type and trip journal
  final PostType postType;
  final String? location;      // Only for trip journal
  final DateTime? tripDate;    // Only for trip journal

  PostModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.content,
    this.musicUrl,
    this.musicTitle,
    required this.timestamp,
    required this.visibility,
    this.postType = PostType.normal,
    this.location,
    this.tripDate,
  });

  // Getter to check if the post is public
  bool get isPublic => visibility == 'public';

  // Setter to set the post visibility
  set isPublic(bool value) {
    visibility = value ? 'public' : 'private';
  }

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
      'postType': postType == PostType.tripJournal ? 'tripJournal' : 'normal',
      'location': location,
      'tripDate': tripDate?.toIso8601String(),
    };
  }

  // Create a PostModel instance from a Firestore document
  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Handle timestamp from Firestore
    DateTime timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      timestamp = DateTime.parse(map['timestamp']);
    } else {
      timestamp = DateTime.now();
    }

    // Determine post type
    PostType type = PostType.normal;
    if (map['postType'] == 'tripJournal') {
      type = PostType.tripJournal;
    }

    return PostModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      content: map['content'] ?? '',
      musicUrl: map['musicUrl'],
      musicTitle: map['musicTitle'],
      timestamp: timestamp,
      visibility: map['visibility'] ?? 'public',
      postType: type,
      location: map['location'],
      tripDate: map['tripDate'] != null && map['tripDate'] != ''
          ? DateTime.tryParse(map['tripDate'])
          : null,
    );
  }

  // Convert to a map specifically for updates (doesn't include timestamp)
  Map<String, dynamic> toUpdateMap() {
    return {
      'visibility': visibility,
      'content': content,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'postType': postType == PostType.tripJournal ? 'tripJournal' : 'normal',
      'location': location,
      'tripDate': tripDate?.toIso8601String(),
    };
  }
}
