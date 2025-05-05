import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    String? status,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    Color backgroundColor;
    switch (status?.toUpperCase()) {
      case 'SAFE':
      case 'SUCCESS':
        backgroundColor = Colors.green[400]!;
        break;
      case 'WARNING':
        backgroundColor = Colors.orange[400]!;
        break;
      case 'UNSAFE':
      case 'ERROR':
        backgroundColor = Colors.red[400]!;
        break;
      default:
        backgroundColor = Colors.grey[400]!;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(4),
        duration: duration,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      ),
    );
  }
}
