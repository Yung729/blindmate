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
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }
}