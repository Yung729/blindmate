// ui_components/loading_indicator.dart
import 'package:flutter/material.dart';

class UIComponents {
  static Widget loadingIndicator({double? width, double? height, double strokeWidth = 2}) {
    return SizedBox(
      width: width,
      height: height,
      child: CircularProgressIndicator(strokeWidth: strokeWidth),
    );
  }
}