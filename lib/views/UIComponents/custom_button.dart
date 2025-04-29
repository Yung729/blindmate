import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double? width;
  final double fontSize;
  final Color? backgroundColor;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.horizontalPadding = 30,
    this.verticalPadding = 15,
    this.borderRadius = 30,
    this.width,
    this.fontSize = 16,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white,
      ),
    );

    if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          buttonChild,
        ],
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.black.withOpacity(0.7),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}