import 'package:flutter/material.dart';

class NetworkImageBox extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final String title;
  final VoidCallback? onTap;

  const NetworkImageBox({
    super.key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.borderRadius = 8,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // handle tap here
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(Icons.broken_image),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: width + 13,
                  height: height + 13,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
