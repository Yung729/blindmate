class UrlUtils {
  /// Returns true if the given string is a valid HTTP/HTTPS URL.
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      return uri != null &&
          (uri.isScheme('http') || uri.isScheme('https')) &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}