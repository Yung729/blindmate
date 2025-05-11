import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final int levelValue;
  final bool online;
  final String status;
  final DateTime? lastActive;
  final String emotionStatus;
  final double progressionValue;
  int fragmentNumber;
  String avatarImg;
  int flower;
  final DateTime surveyDate;
  final List<String> hiddenPosts;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.levelValue,
    required this.online,
    required this.status,
    this.lastActive,
    required this.emotionStatus,
    required this.progressionValue,
    required this.fragmentNumber,
    required this.avatarImg,
    required this.flower,
    required this.surveyDate,
    this.hiddenPosts = const [],
  });

  // 🔹 Convert Firestore Document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: documentId,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'No Email',
      levelValue: (data['levelValue'] as int? ?? 1).clamp(1, 9999),
      online: data['online'] ?? false,
      status: data['status'] ?? 'available',
      lastActive:
          data['lastActive'] != null
              ? (data['lastActive'] as Timestamp).toDate()
              : null,
      emotionStatus: data['emotionStatus'] ?? 'neutral',
      progressionValue: (data['progressionValue'] as num? ?? 0.0)
          .toDouble()
          .clamp(0.0, 1.0),
      fragmentNumber: (data['fragmentNumber'] as num? ?? 0).toInt(),
      avatarImg: data['avatarImg'] ?? '',
      flower: data['flower'] ?? 0,
      surveyDate:
          data['surveyDate'] != null
              ? (data['surveyDate'] as Timestamp).toDate()
              : DateTime.now(),
      hiddenPosts:
          (data['hiddenPosts'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  // 🔹 Convert UserModel to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'online': online,
      'status': status,
      'lastActive':
          lastActive != null
              ? Timestamp.fromDate(lastActive!)
              : FieldValue.serverTimestamp(),
      'emotionStatus': emotionStatus,
      'fragmentNumber': fragmentNumber,
      'avatarImg': avatarImg,
      'levelValue': levelValue,
      'progressionValue': progressionValue,
      'surveyDate': Timestamp.fromDate(surveyDate),
      'hiddenPosts': hiddenPosts,
      'flower': flower,
    };
  }

  // 🔹 Calculate the reward rate based on the user's levelValue
  double getRewardRate() {
    // Calculate reward rate: 1.0 + (floor(levelValue / 10) * 0.5)
    return 1.0 + ((levelValue ~/ 10) * 0.5);
  }
}