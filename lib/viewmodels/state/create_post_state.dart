import 'package:flutter/material.dart';

class CreatePostState extends ChangeNotifier {
  bool isPublic = true;
  bool isLoading = false;
  List<Map<String, String>> musicResults = [];
  String? selectedMusicUrl;
  String? selectedMusicTitle;
  String postContent = '';
  String? _tripLocation;
  DateTime? _tripDate;

  void setIsPublic(bool value) {
    isPublic = value;
    notifyListeners();
  }

  void setIsLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setMusicResults(List<Map<String, String>> results) {
    musicResults = results;
    notifyListeners();
  }

  void selectMusic(String url, String title) {
    selectedMusicUrl = url;
    selectedMusicTitle = title;
    musicResults = []; // Clear results after selection
    notifyListeners();
  }

  void setPostContent(String content) {
    postContent = content;
    notifyListeners();
  }

  void clearMusicSelection() {
    selectedMusicUrl = null;
    selectedMusicTitle = null;
    notifyListeners();
  }

  void clearMusicResults() {
    musicResults = [];
    notifyListeners();
  }

  void reset() {
    isPublic = true;
    isLoading = false;
    musicResults = [];
    selectedMusicUrl = null;
    selectedMusicTitle = null;
    postContent = '';
    notifyListeners();
  }
}
