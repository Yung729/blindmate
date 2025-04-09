import 'package:cloud_firestore/cloud_firestore.dart';

class MissionReward {
  String missionId;
  int rewardFragment;
  bool rewardGiven;
  String rewardId;

  MissionReward({
    required this.missionId,
    required this.rewardFragment,
    required this.rewardGiven,
    required this.rewardId,
  });

  factory MissionReward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MissionReward(
      missionId: data['missionId'] ?? '',
      rewardFragment: data['rewardFragment'] ?? 0,
      rewardGiven: data['rewardGiven'],
      rewardId: data['rewardId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'rewardFragment': rewardFragment,
      'rewardGiven': rewardGiven,
      'rewardId': rewardId,
    };
  }
}
