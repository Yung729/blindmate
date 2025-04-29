import 'package:flutter/material.dart';

class CreatePostState extends ChangeNotifier {
  // Post visibility and loading state
  bool isPublic = true;
  bool isLoading = false;

  // Music-related state
  List<Map<String, String>> musicResults = [];
  String? selectedMusicUrl;
  String? selectedMusicTitle;

  // Link-related state
  String? selectedLinkUrl;
  String? selectedLinkThumbnail;

  // Content state
  String postContent = '';

  // Trip journal state
  List<Map<String, dynamic>> _tripJournals = [];
  bool _isLoadingJournals = false;

  // Getters
  List<Map<String, dynamic>> get tripJournals => _tripJournals;
  bool get isLoadingJournals => _isLoadingJournals;
  bool get hasTripJournals => _tripJournals.isNotEmpty;

  // Post visibility and loading methods
  void setIsPublic(bool value) {
    isPublic = value;
    notifyListeners();
  }

  void setIsLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Link methods
  void setLink(String url, String? thumbnail) {
    selectedLinkUrl = url;
    selectedLinkThumbnail = thumbnail;
    notifyListeners();
  }

  void clearLink() {
    selectedLinkUrl = null;
    selectedLinkThumbnail = null;
    notifyListeners();
  }

  // Music methods
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

  void clearMusicSelection() {
    selectedMusicUrl = null;
    selectedMusicTitle = null;
    notifyListeners();
  }

  void clearMusicResults() {
    musicResults = [];
    notifyListeners();
  }

  // Content methods
  void setPostContent(String content) {
    postContent = content;
    notifyListeners();
  }

  // Trip journal methods
  void setTripJournals(List<Map<String, dynamic>> journals) {
    _tripJournals = journals;
    notifyListeners();
  }

  void clearTripJournals() {
    _tripJournals = [];
    notifyListeners();
  }

  void setLoadingJournals(bool loading) {
    _isLoadingJournals = loading;
    notifyListeners();
  }

  void addTripJournal(Map<String, dynamic> journal) {
    _tripJournals.add(journal);
    notifyListeners();
  }

  void removeTripJournal(int index) {
/// Removes a trip journal entry at the specified index from the list.
/// 
/// If the given index is valid, it removes the trip journal entry at that index 
/// and notifies listeners about the change.
    if (index >= 0 && index < _tripJournals.length) {
/// - Parameter index: The position of the trip journal entry to be removed.
/// - Preconditions: `index` must be within the bounds of the trip journal list.

      notifyListeners();
    }
  }

  void updateTripJournal(int index, Map<String, dynamic> journal) {
    if (index >= 0 && index < _tripJournals.length) {
      _tripJournals[index] = journal;
      notifyListeners();
    }
  }

  // Reset all state
  void reset() {
    // Reset post visibility and loading
    isPublic = true;
    isLoading = false;

    // Reset music state
    musicResults = [];
    selectedMusicUrl = null;
    selectedMusicTitle = null;

    // Reset link state
    selectedLinkUrl = null;
    selectedLinkThumbnail = null;

    // Reset content
    postContent = '';

    // Reset trip journals
    _tripJournals = [];
    _isLoadingJournals = false;

    notifyListeners();
  }

  // Validation methods
  bool canAddTripJournal() {
    return selectedMusicUrl == null; // Can't add trip journal if music is selected
  }

  bool canAddMusic() {
    return _tripJournals.isEmpty; // Can't add music if trip journal exists
  }
}