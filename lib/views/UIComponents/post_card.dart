import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final Color? color;

  const PostCard({
    Key? key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    this.color,
  }) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipPath(
        clipper: WaveClipper(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF81D4FA), // Wave top - brighter blue
                  const Color(0xFFB3E5FC), // Wave middle - medium blue
                  const Color(0xFFE1F5FE), // Content area - light blue
                ],
                stops: const [0.0, 0.08, 0.2], // Subtle transition for wave area
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom clipper for a wavy (water-like) top edge
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 12);

    // Draw a wave at the top
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 12);
    path.quadraticBezierTo(size.width * 0.75, 24, size.width, 12);
    path.lineTo(size.width, 0);

    // Right edge
    path.lineTo(size.width, size.height);
    // Bottom edge
    path.lineTo(0, size.height);
    // Left edge
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
