import 'package:cloud_firestore/cloud_firestore.dart';

class UserReward {
  String userId;
  final List<dynamic> redeemedRewards;
  

  UserReward({
    required this.userId,
    required this.redeemedRewards,
  });

  factory UserReward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic> ?? {};

    return UserReward(
      userId: data['userId'] ?? '',
      redeemedRewards: List<dynamic>.from(data['redeemedReward'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'redeemedReward': redeemedRewards,
    };
  }
}
