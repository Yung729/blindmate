import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final int levelValue;
  final bool online;
  final String status;
  final DateTime? lastActive;
  final String emotionalStatus;
  final double progressionValue;
  int fragmentNumber;
  final String currentMission;
  final DateTime surveyDate; 

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.levelValue,
    required this.online,
    required this.status,
    this.lastActive,
    required this.emotionalStatus,
    required this.progressionValue,
    required this.fragmentNumber,
    required this.currentMission,
    required this.surveyDate, 
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: documentId,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'No Email',
      levelValue: (data['levelValue'] as int? ?? 1).clamp(1, 9999),
      online: data['online'] ?? false,
      status: data['status'] ?? 'available',
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      emotionalStatus: data['emotionalStatus'] ?? 'neutral',
      progressionValue: (data['progressionValue'] as num? ?? 0.0)
          .toDouble()
          .clamp(0.0, 1.0),
      fragmentNumber: data['fragmentNumber'] ?? 0,
      currentMission: data['currentMission'] ?? '',
      surveyDate: data['surveyDate'] != null
          ? (data['surveyDate'] as Timestamp).toDate()
          : DateTime.now(), 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'online': online,
      'status': status,
      'lastActive': lastActive != null
          ? Timestamp.fromDate(lastActive!)
          : FieldValue.serverTimestamp(),
      'emotionalStatus': emotionalStatus,
      'fragmentNumber': fragmentNumber,
      'currentMission': currentMission,
      'levelValue': levelValue,
      'progressionValue': progressionValue,
      'surveyDate': Timestamp.fromDate(surveyDate), // Include in map
    };
  }
}
