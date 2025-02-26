import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email; // 🔹 Added email field
  final int mentalHealthLevel;
  final bool online;
  final String status;
  final DateTime? lastActive; // 🔹 Added lastActive field

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.mentalHealthLevel,
    required this.online,
    required this.status,
    this.lastActive, // Can be null if user never logged in
  });

  // 🔹 Convert Firestore Document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: documentId, // Use Firestore doc ID as userId
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'No Email', // 🔹 Default if missing
      mentalHealthLevel: (data['mentalHealthLevel'] ?? 1).toInt(),
      online: data['online'] ?? false,
      status: data['status'] ?? 'available',
      lastActive:
          data['lastActive'] != null
              ? (data['lastActive'] as Timestamp).toDate()
              : null, // 🔹 Convert Firestore Timestamp
    );
  }

  // 🔹 Convert UserModel to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'mentalHealthLevel': mentalHealthLevel,
      'online': online,
      'status': status,
      'lastActive':
          lastActive != null
              ? Timestamp.fromDate(lastActive!)
              : FieldValue.serverTimestamp(),
    };
  }
}
