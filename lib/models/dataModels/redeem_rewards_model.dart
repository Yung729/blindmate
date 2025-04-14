class RewardModel {
  final String redeemRewardId;
  final int fragmentCost;
  final String imageUrl;

  RewardModel({
    required this.redeemRewardId,
    required this.fragmentCost,
    required this.imageUrl,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      redeemRewardId: json['redeemRewardId'] ?? '',
      fragmentCost: json['fragmentCost'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'redeemRewardId': redeemRewardId,
      'fragmentCost': fragmentCost,
      'imageUrl': imageUrl,
    };
  }
}
