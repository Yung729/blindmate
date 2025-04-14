import 'package:flutter/material.dart';

class RewardButton extends StatelessWidget {
  final String imagePath;
  final String title;
  final int cost;
  final VoidCallback onPressed;

  const RewardButton({
    super.key,
    required this.imagePath,
    required this.title,
    required this.cost,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "fragment cost:",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          Text(
            "$cost",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
