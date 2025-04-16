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
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipPath(
        clipper: WaveClipper(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // 👈 just slightly rounded
          child: Container(
            decoration: BoxDecoration(
              color: color ?? Color(0xFFE3F2FD), // Light blue sea theme
            ),
            child: Padding(padding: const EdgeInsets.all(12.0), child: child),
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
