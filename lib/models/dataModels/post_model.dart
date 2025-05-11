import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { normal, tripJournal, musicPost, urlPost }

class PostModel {
  final String? id;
  final String userId;
  final String userName;
  final String content;
  final String? url;
  final String? musicUrl;
  final String? musicTitle;
  final DateTime timestamp;
  String visibility; // Made non-final to allow modification
  final List<Map<String, dynamic>>? tripJournals;

  // Only postType remains for distinguishing post types
  final PostType postType;

  /// Optional: The author's avatar URL, to be set after fetching posts
  String? authorAvatar;

  PostModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.content,
    this.url, // Added to constructor
    this.musicUrl,
    this.musicTitle,
    required this.timestamp,
    required this.visibility,
    this.postType = PostType.normal,
    this.tripJournals,
    this.authorAvatar, // <-- Add to constructor
  });

  // Getter to check if the post is public
  bool get isPublic {
    if (visibility == 'deleted') return false;
    return visibility == 'public';
  }

  bool get isDeleted => visibility == 'deleted';

  // Setter to set the post visibility
  set isPublic(bool value) {
    visibility = value ? 'public' : 'private';
  }

  // Convert the PostModel instance into a Map to store in Firestore
  Map<String, dynamic> toMap() {
    // Ensure each tripJournal has a tripId if not already present
    final processedTripJournals = tripJournals?.map((journal) {
      if (!journal.containsKey('tripId')) {
        // Generate a unique ID if one doesn't exist
        return {
          ...journal,
          'tripId': DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }
      return journal;
    }).toList();

    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'url': url,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'timestamp': FieldValue.serverTimestamp(),
      'visibility': visibility,
      'postType': _postTypeToString(postType),
      'tripJournals': processedTripJournals,
      // Do NOT include authorAvatar in Firestore, it's for UI only
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
    PostType type = _stringToPostType(map['postType']);

    // Deserialize tripJournals if present
    List<Map<String, dynamic>>? tripJournals;
    if (map['tripJournals'] != null) {
      tripJournals = List<Map<String, dynamic>>.from(
        (map['tripJournals'] as List).map((e) {
          final journal = Map<String, dynamic>.from(e);
          final date = journal['date'];
          journal['date'] = date is Timestamp ? date.toDate() : date;
          
          // Ensure each journal has a tripId
          if (!journal.containsKey('tripId')) {
            journal['tripId'] = '${documentId}_${journal.hashCode}';
          }
          
          return journal;
        }),
      );
    }

    return PostModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      content: map['content'] ?? '',
      url: map['url'],
      musicUrl: map['musicUrl'],
      musicTitle: map['musicTitle'],
      timestamp: timestamp,
      visibility: map['visibility'] ?? 'public',
      postType: type,
      tripJournals: tripJournals,
      // authorAvatar is not set here; set it after fetching avatars
    );
  }

  // Convert to a map specifically for updates (doesn't include timestamp)
  Map<String, dynamic> toUpdateMap() {
    // Ensure each tripJournal has a tripId if not already present
    final processedTripJournals = tripJournals?.map((journal) {
      if (!journal.containsKey('tripId')) {
        // Generate a unique ID if one doesn't exist
        return {
          ...journal,
          'tripId': DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }
      return journal;
    }).toList();

    return {
      'visibility': visibility,
      'content': content,
      'url': url,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'postType': _postTypeToString(postType),
      'tripJournals': processedTripJournals,
      // Do NOT include authorAvatar in Firestore
    };
  }

  static String _postTypeToString(PostType type) {
    switch (type) {
      case PostType.tripJournal:
        return 'tripJournal';
      case PostType.musicPost:
        return 'musicPost';
      case PostType.urlPost:
        return 'urlPost';
      case PostType.normal:
        return 'normal';
    }
  }

  /// Helper: Convert string from Firestore to PostType enum
  static PostType _stringToPostType(dynamic value) {
    switch (value) {
      case 'tripJournal':
        return PostType.tripJournal;
      case 'musicPost':
        return PostType.musicPost;
      case 'urlPost':
        return PostType.urlPost;
      case 'normal':
      default:
        return PostType.normal;
    }
  }
}