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
    required this.progressionValue,
    required this.fragmentNumber,
    required this.currentMission,
  });

  // Fetch user data, including the 'level' subcollection
  static Future<UserModel> fromMap(Map<String, dynamic> data, String documentId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch the 'level' subcollection
    DocumentSnapshot levelDoc = await firestore
        .collection('users')
        .doc(documentId)
        .collection('level')
        .doc('current')
        .get();

    int levelValue = 1; // Default
    double progressionValue = 0.0; // Default

    if (levelDoc.exists) {
      final levelData = levelDoc.data() as Map<String, dynamic>;
      levelValue = (levelData['levelValue'] as int? ?? 1).clamp(1, 9999);
      progressionValue = (levelData['progressionValue'] as num? ?? 0.0).toDouble().clamp(0.0, 1.0);
    } else {
      // If 'level' subcollection doesn't exist, create it with default values
      await firestore
          .collection('users')
          .doc(documentId)
          .collection('level')
          .doc('current')
          .set({
        'levelValue': 1,
        'progressionValue': 0.0,
      });
    }

    return UserModel(
      userId: documentId,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? 'No Email',
      levelValue: levelValue,
      online: data['online'] ?? false,
      status: data['status'] ?? 'available',
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      emotionalStatus: data['emotionalStatus'] ?? 'neutral',
      progressionValue: progressionValue,
      fragmentNumber: data['fragmentNumber'] ?? 0,
      currentMission: data['currentMission'] ?? '',
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
    };
  }

  Map<String, dynamic> toLevelMap() {
    return {
      'levelValue': levelValue,
      'progressionValue': progressionValue,
    };
  }
}