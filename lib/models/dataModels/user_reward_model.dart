import 'package:cloud_firestore/cloud_firestore.dart';

class UserReward {
  String userId;
  int fragmentNumber;
  String currentMission;

  UserReward({
    required this.userId,
    required this.fragmentNumber,
    required this.currentMission,
  });

  factory UserReward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserReward(
      userId: data['userId'] ?? '',
      fragmentNumber: data['fragmentNumber'] ?? 0,
      currentMission: data['currentMission'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fragmentNumber': fragmentNumber,
      'currentMission': currentMission,
    };
  }
}
