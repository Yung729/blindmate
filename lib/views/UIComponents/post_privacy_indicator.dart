// ui_components/post_privacy_indicator.dart
import 'package:flutter/material.dart';

class PostPrivacyIndicator extends StatelessWidget {
  final String privacy;
  final double? size;
  final Color? color;

  const PostPrivacyIndicator({
    super.key,
    required this.privacy,
    this.size = 16,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    switch (privacy) {
      case 'public':
        return Icon(Icons.public, size: size, color: color);
      case 'private':
        return Icon(Icons.lock, size: size, color: color);
      // Add more cases if you have other privacy settings
      default:
        return const SizedBox.shrink(); // Or a default icon
    }
  }
}