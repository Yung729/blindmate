import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final int levelValue; // Non-nullable, starts at 1
  final bool online;
  final String status;
  final DateTime? lastActive;
  final String emotionalStatus;
  final double levelProgress; // Between 0.0 and 1.0
  final int fragmentNumber;
  final String currentMission;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.levelValue,
    required this.online,
    required this.status,
    this.lastActive,
    required this.emotionalStatus,
    required this.levelProgress,
    required this.fragmentNumber,
    required this.currentMission,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: documentId,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'No Email',
      levelValue: (data['mentalLevel'] as int? ?? 1).clamp(1, 9999), // Default to 1, max 9999
      online: data['online'] ?? false,
      status: data['status'] ?? 'available',
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      emotionalStatus: data['emotionalStatus'] ?? 'neutral',
      levelProgress: (data['levelProgress'] as num? ?? 0.0).toDouble().clamp(0.0, 1.0), // Ensure between 0.0 and 1.0
      fragmentNumber: data['fragmentNumber'] ?? 0,
      currentMission: data['currentMission'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'mentalLevel': levelValue,
      'online': online,
      'status': status,
      'lastActive': lastActive != null
          ? Timestamp.fromDate(lastActive!)
          : FieldValue.serverTimestamp(),
      'emotionalStatus': emotionalStatus,
      'levelProgress': levelProgress,
      'fragmentNumber': fragmentNumber,
      'currentMission': currentMission,
    };
  }
}