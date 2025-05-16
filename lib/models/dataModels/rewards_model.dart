import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String redeemRewardId;
  final int fragmentCost;
  final String imageUrl;
  final String rewardTitle;
  // Non-final property to temporarily store quantity for multiple redemptions
  int quantity = 1;

  RewardModel({
    required this.redeemRewardId,
    required this.fragmentCost,
    required this.imageUrl,
    required this.rewardTitle,
    this.quantity = 1,
  });

  factory RewardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RewardModel(
      redeemRewardId: doc.id,
      fragmentCost: data['fragmentCost'] ?? 0,
      imageUrl: data['imgUrl'] ?? '',
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
