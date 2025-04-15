import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String redeemRewardId;
  final int fragmentCost;
  final String imageUrl;
  final String rewardTitle;

  RewardModel({
    required this.redeemRewardId,
    required this.fragmentCost,
    required this.imageUrl,
    required this.rewardTitle,
  });

  factory RewardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardModel(
      redeemRewardId: doc.id,
      fragmentCost: data['fragmentCost'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      rewardTitle: data['rewardTitle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'redeemRewardId': redeemRewardId,
      'fragmentCost': fragmentCost,
      'imageUrl': imageUrl,
      'rewardTitle':rewardTitle,
    };
  }
}
