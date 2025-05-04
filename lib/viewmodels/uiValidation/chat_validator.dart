class MessageValidator {
  /// Validates if a text message is valid (not empty after trimming)
  static bool isValid(String message) {
    return message.trim().isNotEmpty;
  }
  
  /// Validates if a message has any content (text, sticker, or music)
  static bool hasContent({
    String? text,
    String? stickerUrl,
    String? musicUrl,
  }) {
    return (text != null && isValid(text)) ||
           (stickerUrl != null && stickerUrl.isNotEmpty) ||
           (musicUrl != null && musicUrl.isNotEmpty);
  }
}
