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

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      redeemRewardId: json['redeemRewardId'] ?? '',
      fragmentCost: json['fragmentCost'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      rewardTitle: json['rewardTitle'] ?? '',
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
