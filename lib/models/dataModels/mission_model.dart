import 'package:cloud_firestore/cloud_firestore.dart';

class MissionData {
  final String assignedUserReward;
  String description;
  Timestamp dueDate;
  String status;
  String title;

  MissionData({
    required this.assignedUserReward,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.title,
  });

  factory MissionData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MissionData(
      assignedUserReward: data['assignedUserReward'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] ?? Timestamp.now(),
      status: data['status'] ?? '',
      title: data['title'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedUserReward': assignedUserReward,
      'description': description,
      'dueDate': dueDate,
      'status': status,
      'title': title,
    };
  }
}
