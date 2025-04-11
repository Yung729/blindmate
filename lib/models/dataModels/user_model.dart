import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email; // 🔹 Added email field
  final int mentalLevel;
  final bool online;
  final String status;
  final DateTime? lastActive; // 🔹 Added lastActive field
  final String emotionalStatus; 
  final double levelProgress; // Ensure this is non-nullable
  
  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.mentalLevel,
    required this.online,
    required this.status,
    this.lastActive, // Can be null if user never logged in
    required this.emotionalStatus,
    required this.levelProgress,
  });

  // 🔹 Convert Firestore Document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: documentId, // Use Firestore doc ID as userId
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'No Email', // 🔹 Default if missing
      mentalLevel: (data['mentalLevel'] ?? 1).toInt(),
      online: data['online'] ?? false,
      status: data['status'] ?? 'available',
      lastActive:
          data['lastActive'] != null
              ? (data['lastActive'] as Timestamp).toDate()
              : null, // 🔹 Convert Firestore Timestamp
      emotionalStatus: data['emotionalStatus'] ?? 'neutral',
      levelProgress: data['levelProgress'] ?? 0
    );
  }

  // 🔹 Convert UserModel to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'mentalLevel': mentalLevel,
      'online': online,
      'status': status,
      'lastActive':
          lastActive != null
              ? Timestamp.fromDate(lastActive!)
              : FieldValue.serverTimestamp(),
    };
  }
}
