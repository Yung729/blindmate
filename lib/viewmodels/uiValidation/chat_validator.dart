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

  /// Checks if a message contains sensitive information that should be restricted
  static bool containsSensitiveInfo(String message) {
    
    // Check for email addresses
    if (_containsEmail(message)) {
      return true;
    }
    
    // Check for phone numbers (various formats)
    if (_containsPhoneNumber(message)) {
      return true;
    }

    // Check for physical addresses
    if (_containsAddress(message)) {
      return true;
    }

    return false;
  }

  /// Sanitizes a message by masking sensitive information with asterisks
  static String sanitizeSensitiveInfo(String message) {
    
    // Mask phone numbers with asterisks
    String result = message;
    
    // Phone numbers
    result = _maskPhoneNumbersWithAsterisks(result);
    
    // Email addresses
    result = _maskEmailsWithAsterisks(result);
    
    // Addresses
    result = _maskAddressesWithAsterisks(result);
    
    return result;
  }

  /// Returns a sanitized version of the message with sensitive info masked
  static String sanitizeMessage(String message) {
    // Mask phone numbers
    String sanitized = _maskPhoneNumbers(message);
    
    // Mask email addresses
    sanitized = _maskEmails(sanitized);
    
    // Mask addresses
    sanitized = _maskAddresses(sanitized);
    
    return sanitized;
  }

  /// Gets the type of sensitive information found in the message, or null if none
  static String? getSensitiveInfoType(String message) {
    if (_containsPhoneNumber(message)) {
      return 'phone number';
    }
    if (_containsEmail(message)) {
      return 'email address';
    }
    if (_containsAddress(message)) {
      return 'address';
    }
    return null;
  }

  /// Returns an error message explaining why the message was rejected
  static String getErrorMessage(String message) {
    final infoType = getSensitiveInfoType(message);
    switch (infoType) {
      case 'phone number':
        return "🛡️ For your privacy and safety, sharing phone numbers is not allowed.";
      case 'email address':
        return "🛡️ For your privacy and safety, sharing email addresses is not allowed.";
      case 'address':
        return "🛡️ For your privacy and safety, sharing physical addresses is not allowed.";
      default:
        return "🛡️ For your privacy and safety, sharing personal contact information is not allowed.";
    }
  }

  /// Returns a helpful message with suggestions for the user
  static String getHelpfulSuggestion(String message) {
    final infoType = getSensitiveInfoType(message);
    switch (infoType) {
      case 'phone number':
        return "Consider getting to know your match better before sharing contact information.";
      case 'email address':
        return "It's better to keep conversations within the app for your safety.";
      case 'address':
        return "For your safety, avoid sharing your location or address with people you've just met.";
      default:
        return "Please continue chatting within the app for your safety.";
    }
  }

  // Pre-compiled RegExp patterns
  static final RegExp _phonePattern = RegExp(
    r'(?:\b01[0-9]-[0-9]{7,8}\b)|'
    r'(?:\b01[0-9][0-9]{7,8}\b)|'
    r'(?:\+601[0-9][0-9]{7,8}\b)|'
    r'(?:\b601[0-9][0-9]{7,8}\b)|'
    r'(?:\b0[0-9]-[0-9]{7,8}\b)|'
    r'(?:\b0[0-9][0-9]{7,8}\b)|'
    r'(?:\+60[0-9]{8,10}\b)|'
    r'(?:\b\d{10}\b)|'
    r'(?:\b\d{3}-\d{3}-\d{4}\b)|'
    r'(?:\b\d{3} \d{3} \d{4}\b)|'
    r'(?:\(\d{3}\) ?\d{3}-\d{4})|'
    r'(?:\+\d{1,3} ?\d{3} ?\d{3} ?\d{4})|'
    r'(?:\b\d{3}\.\d{3}\.\d{4}\b)',
  );

  static final RegExp _emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');

  static final RegExp _addressPattern = RegExp(
    r'(?:\b\d{5}\s+[A-Za-z\s]+\b)|'
    r'(?:\bJalan\s+[A-Za-z0-9\s]+\b)|'
    r'(?:\bLorong\s+[A-Za-z0-9\s]+\b)|'
    r'(?:\bPersiaran\s+[A-Za-z0-9\s]+\b)|'
    r'(?:\bTaman\s+[A-Za-z0-9\s]+\b)|'
    r'(?:\bKampung\s+[A-Za-z0-9\s]+\b)|'
    r'(?:\b(?:Selangor|Kuala Lumpur|Johor|Penang|Perak|Kedah|Kelantan|Sabah|Sarawak|Melaka|Negeri Sembilan|Pahang|Terengganu|Perlis|Putrajaya|Labuan)[,\s]+Malaysia\b)|'
    r'(?:\bNo\.\s*\d+[A-Za-z]?[,\s]+)|'
    r'(?:\bUnit\s+\d+[A-Za-z]?[,\s]+)|'
    r'(?:\b\d+\s+[A-Za-z]+\s+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr)\b)|'
    r'(?:\bP\.?O\.?\s*Box\s+\d+\b)|'
    r'(?:\b\d{5}(?:-\d{4})?\b)|'
    r'(?:\b[A-Za-z\s]+,\s*[A-Z]{2}\b)',
    caseSensitive: false,
  );

  // Private helper methods

  /// Checks if text contains a phone number pattern
  static bool _containsPhoneNumber(String text) {
    return _phonePattern.hasMatch(text);
  }

  /// Checks if text contains an email address
  static bool _containsEmail(String text) {
    return _emailPattern.hasMatch(text);
  }

  /// Checks if text potentially contains a physical address
  static bool _containsAddress(String text) {
    return _addressPattern.hasMatch(text);
  }

  /// Masks phone numbers with asterisks (****) preserving some format characters
  static String _maskPhoneNumbersWithAsterisks(String text) {
    return text.replaceAllMapped(_phonePattern, (match) {
      String phoneNum = match.group(0)!;
      // Keep first 2 digits and special chars, replace the rest with asterisks
      String masked = phoneNum.replaceAllMapped(
        RegExp(r'\d'), // This inner RegExp is fine
        (digitMatch) => digitMatch.start < 2 ? digitMatch.group(0)! : '*'
      );
      return masked;
    });
  }

  /// Masks email addresses with asterisks, preserving domain
  static String _maskEmailsWithAsterisks(String text) {
    return text.replaceAllMapped(_emailPattern, (match) {
      final username = match.group(1)!;
      final domain = match.group(2)!;
      
      // Show first character of username, mask the rest
      String maskedUsername = username.substring(0, 1) + 
                              '*' * (username.length > 1 ? username.length - 1 : 0);
      
      return '$maskedUsername@$domain';
    });
  }

  /// Masks addresses with asterisks
  static String _maskAddressesWithAsterisks(String text) {
    return text.replaceAllMapped(_addressPattern, (match) {
      String address = match.group(0)!;
      // Keep address type prefixes like "Jalan", "Taman", etc.
      List<String> prefixes = [
        'Jalan', 'Lorong', 'Persiaran', 'Taman', 'Kampung',
        'Street', 'St', 'Avenue', 'Ave', 'Road', 'Rd',
        'Boulevard', 'Blvd', 'Lane', 'Ln', 'Drive', 'Dr',
        'P.O. Box', 'PO Box', 'Unit', 'No.'
      ];
      
      for (String prefixStr in prefixes) {
        String escapedPrefix = RegExp.escape(prefixStr);
        RegExp prefixRegExp = RegExp(r'\b' + escapedPrefix + r'\b', caseSensitive: false);
        Match? prefixMatch = prefixRegExp.firstMatch(address);

        if (prefixMatch != null) {
          int prefixEndIndex = prefixMatch.end;
          String masked = address.substring(0, prefixEndIndex) + ' ****';
          return masked;
        }
      }
      
      // If no prefix match, mask the entire address except the first word
      List<String> parts = address.split(' ');
      if (parts.length > 1) {
        return parts[0] + ' ****';
      } else {
        return '****';
      }
    });
  }

  /// Masks phone numbers in text
  static String _maskPhoneNumbers(String text) {
    return text.replaceAllMapped(_phonePattern, (match) => '[phone number removed]');
  }

  /// Masks email addresses in text
  static String _maskEmails(String text) {
    return text.replaceAllMapped(_emailPattern, (match) => '[email removed]');
  }

  /// Masks addresses in text
  static String _maskAddresses(String text) {
    return text.replaceAllMapped(_addressPattern, (match) => '[address removed]');
  }
}
