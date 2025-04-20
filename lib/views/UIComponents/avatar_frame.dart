import 'package:flutter/material.dart';

class AvatarFrame extends StatelessWidget {
  final VoidCallback? onTap;
  final String imagePath; // Image path parameter
  final double width; // Adjustable width
  final double height; // Adjustable height

  const AvatarFrame({
    super.key,
    this.onTap,
    required this.imagePath, // Make the imagePath parameter required
    this.width = 50, // Default width
    this.height = 50, // Default height
  });

  @override
  Widget build(BuildContext context) {
    String finalImagePath =
        imagePath.isEmpty
            ? 'https://tse3.mm.bing.net/th/id/OIP.XXbgSKiEDzYZDqZQ4hYfvQHaHu?rs=1&pid=ImgDetMain' // Default image
            : imagePath; // Use provided image path if not empty
    return Positioned(
      top: 0,
      left: 0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10),
          width: width, // Use adjustable width
          height: height, // Use adjustable height
          decoration: BoxDecoration(
            shape: BoxShape.circle, // This will make the container circular
          ),
          child: ClipOval(
            child: Image.network(
              finalImagePath, // Use the imagePath variable
              fit: BoxFit.fill, // Ensures the image fills the container
            ),
          ),
        ),
      ),
    );
  }
}
