class UIValidation {
  /// Returns true if at least one of the post fields is non-empty.
  static bool isPostValid({
    required String postContent,
    required String? musicUrl,
    required String? linkUrl,
    required List<Map<String, dynamic>> tripJournals,
  }) {
    return postContent.trim().isNotEmpty ||
        (musicUrl != null && musicUrl.isNotEmpty) ||
        (linkUrl != null && linkUrl.isNotEmpty) ||
        tripJournals.isNotEmpty;
  }
}