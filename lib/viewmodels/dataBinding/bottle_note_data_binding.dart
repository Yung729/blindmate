import 'package:flutter/material.dart';

class BottleNoteDataBinding {
  final TextEditingController contentController = TextEditingController();
  String? selectedSticker;

  void clear() {
    contentController.clear();
    selectedSticker = null;
  }

  void dispose() {
    contentController.dispose();
  }
}