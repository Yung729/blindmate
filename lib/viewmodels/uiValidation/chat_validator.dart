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
    // Check for phone numbers (various formats)
    if (_containsPhoneNumber(message)) {
      return true;
    }

    // Check for email addresses
    if (_containsEmail(message)) {
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
    if (!containsSensitiveInfo(message)) {
      return message; // No sensitive info to mask
    }
    
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

  // Private helper methods

  /// Checks if text contains a phone number pattern
  static bool _containsPhoneNumber(String text) {
    // Common phone number patterns including Malaysian formats
    final List<RegExp> phonePatterns = [
      // Malaysian mobile numbers (e.g., 012-3456789, 0123456789, +60123456789)
      RegExp(r'\b01[0-9]-[0-9]{7,8}\b'),  // With hyphen
      RegExp(r'\b01[0-9][0-9]{7,8}\b'),   // Without hyphen
      RegExp(r'\+601[0-9][0-9]{7,8}\b'),  // With country code +60
      RegExp(r'\b601[0-9][0-9]{7,8}\b'),  // With country code without +
      
      // Malaysian landline numbers (e.g., 03-12345678, 0312345678)
      RegExp(r'\b0[0-9]-[0-9]{7,8}\b'),  // With hyphen
      RegExp(r'\b0[0-9][0-9]{7,8}\b'),   // Without hyphen
      
      // International format for Malaysian numbers
      RegExp(r'\+60[0-9]{8,10}\b'),
      
      // General formats (keep for backward compatibility)
      RegExp(r'\b\d{10}\b'),
      RegExp(r'\b\d{3}-\d{3}-\d{4}\b'),
      RegExp(r'\b\d{3} \d{3} \d{4}\b'),
      RegExp(r'\(\d{3}\) ?\d{3}-\d{4}'),
      RegExp(r'\+\d{1,3} ?\d{3} ?\d{3} ?\d{4}'),
      RegExp(r'\b\d{3}\.\d{3}\.\d{4}\b'),
    ];

    for (var pattern in phonePatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if text contains an email address
  static bool _containsEmail(String text) {
    // Simple email pattern
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    return emailPattern.hasMatch(text);
  }

  /// Checks if text potentially contains a physical address
  static bool _containsAddress(String text) {
    // Address patterns including Malaysian formats
    final List<RegExp> addressPatterns = [
      // Malaysian address format with postcode (e.g., 50000 Kuala Lumpur)
      RegExp(r'\b\d{5}\s+[A-Za-z\s]+\b', caseSensitive: false),
      
      // Common Malaysian address terms
      RegExp(r'\bJalan\s+[A-Za-z0-9\s]+\b', caseSensitive: false), // Street
      RegExp(r'\bLorong\s+[A-Za-z0-9\s]+\b', caseSensitive: false), // Lane
      RegExp(r'\bPersiaran\s+[A-Za-z0-9\s]+\b', caseSensitive: false), // Drive
      RegExp(r'\bTaman\s+[A-Za-z0-9\s]+\b', caseSensitive: false), // Garden/Park
      RegExp(r'\bKampung\s+[A-Za-z0-9\s]+\b', caseSensitive: false), // Village
      
      // Malaysian state names followed by Malaysia
      RegExp(r'\b(?:Selangor|Kuala Lumpur|Johor|Penang|Perak|Kedah|Kelantan|Sabah|Sarawak|Melaka|Negeri Sembilan|Pahang|Terengganu|Perlis|Putrajaya|Labuan)[,\s]+Malaysia\b', caseSensitive: false),
      
      // Unit/house number patterns common in Malaysia
      RegExp(r'\bNo\.\s*\d+[A-Za-z]?[,\s]+', caseSensitive: false),
      RegExp(r'\bUnit\s+\d+[A-Za-z]?[,\s]+', caseSensitive: false),
      
      // Common international formats (keep for backward compatibility)
      RegExp(r'\b\d+\s+[A-Za-z]+\s+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr)\b', caseSensitive: false),
      RegExp(r'\bP\.?O\.?\s*Box\s+\d+\b', caseSensitive: false),
      RegExp(r'\b\d{5}(?:-\d{4})?\b'),
      RegExp(r'\b[A-Za-z\s]+,\s*[A-Z]{2}\b'),
    ];

    for (var pattern in addressPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Masks phone numbers with asterisks (****) preserving some format characters
  static String _maskPhoneNumbersWithAsterisks(String text) {
    // Use the same patterns as in _containsPhoneNumber
    final List<RegExp> phonePatterns = [
      // Malaysian mobile numbers
      RegExp(r'\b01[0-9]-[0-9]{7,8}\b'),
      RegExp(r'\b01[0-9][0-9]{7,8}\b'),
      RegExp(r'\+601[0-9][0-9]{7,8}\b'),
      RegExp(r'\b601[0-9][0-9]{7,8}\b'),
      
      // Malaysian landline numbers
      RegExp(r'\b0[0-9]-[0-9]{7,8}\b'),
      RegExp(r'\b0[0-9][0-9]{7,8}\b'),
      
      // International format for Malaysian numbers
      RegExp(r'\+60[0-9]{8,10}\b'),
      
      // General formats
      RegExp(r'\b\d{10}\b'),
      RegExp(r'\b\d{3}-\d{3}-\d{4}\b'),
      RegExp(r'\b\d{3} \d{3} \d{4}\b'),
      RegExp(r'\(\d{3}\) ?\d{3}-\d{4}'),
      RegExp(r'\+\d{1,3} ?\d{3} ?\d{3} ?\d{4}'),
      RegExp(r'\b\d{3}\.\d{3}\.\d{4}\b'),
    ];

    String result = text;
    for (var pattern in phonePatterns) {
      result = result.replaceAllMapped(pattern, (match) {
        String phoneNum = match.group(0)!;
        // Keep first 2 digits and special chars, replace the rest with asterisks
        String masked = phoneNum.replaceAllMapped(
          RegExp(r'\d'),
          (digitMatch) => digitMatch.start < 2 ? digitMatch.group(0)! : '*'
        );
        return masked;
      });
    }
    return result;
  }

  /// Masks email addresses with asterisks, preserving domain
  static String _maskEmailsWithAsterisks(String text) {
    final emailPattern = RegExp(r'\b([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Z|a-z]{2,})\b');
    return text.replaceAllMapped(emailPattern, (match) {
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
    // Use the same patterns as in _containsAddress
    final List<RegExp> addressPatterns = [
      // Malaysian address format with postcode
      RegExp(r'\b\d{5}\s+[A-Za-z\s]+\b', caseSensitive: false),
      
      // Common Malaysian address terms
      RegExp(r'\bJalan\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bLorong\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bPersiaran\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bTaman\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bKampung\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      
      // Malaysian state names followed by Malaysia
      RegExp(r'\b(?:Selangor|Kuala Lumpur|Johor|Penang|Perak|Kedah|Kelantan|Sabah|Sarawak|Melaka|Negeri Sembilan|Pahang|Terengganu|Perlis|Putrajaya|Labuan)[,\s]+Malaysia\b', caseSensitive: false),
      
      // Unit/house number patterns common in Malaysia
      RegExp(r'\bNo\.\s*\d+[A-Za-z]?[,\s]+', caseSensitive: false),
      RegExp(r'\bUnit\s+\d+[A-Za-z]?[,\s]+', caseSensitive: false),
      
      // Common international formats
      RegExp(r'\b\d+\s+[A-Za-z]+\s+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr)\b', caseSensitive: false),
      RegExp(r'\bP\.?O\.?\s*Box\s+\d+\b', caseSensitive: false),
      RegExp(r'\b\d{5}(?:-\d{4})?\b'),
      RegExp(r'\b[A-Za-z\s]+,\s*[A-Z]{2}\b'),
    ];

    String result = text;
    for (var pattern in addressPatterns) {
      result = result.replaceAllMapped(pattern, (match) {
        String address = match.group(0)!;
        // Keep address type prefixes like "Jalan", "Taman", etc.
        List<String> prefixes = [
          'Jalan', 'Lorong', 'Persiaran', 'Taman', 'Kampung',
          'Street', 'St', 'Avenue', 'Ave', 'Road', 'Rd',
          'Boulevard', 'Blvd', 'Lane', 'Ln', 'Drive', 'Dr',
          'P.O. Box', 'PO Box', 'Unit', 'No.'
        ];
        
        for (String prefix in prefixes) {
          RegExp prefixPattern = RegExp(r'\b' + prefix + r'\b', caseSensitive: false);
          if (prefixPattern.hasMatch(address)) {
            // Keep the prefix, replace everything after it with asterisks
            int prefixEndIndex = address.toLowerCase().indexOf(prefix.toLowerCase()) + prefix.length;
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
    return result;
  }

  /// Masks phone numbers in text
  static String _maskPhoneNumbers(String text) {
    // Use the same patterns as in _containsPhoneNumber
    final List<RegExp> phonePatterns = [
      // Malaysian mobile numbers
      RegExp(r'\b01[0-9]-[0-9]{7,8}\b'),
      RegExp(r'\b01[0-9][0-9]{7,8}\b'),
      RegExp(r'\+601[0-9][0-9]{7,8}\b'),
      RegExp(r'\b601[0-9][0-9]{7,8}\b'),
      
      // Malaysian landline numbers
      RegExp(r'\b0[0-9]-[0-9]{7,8}\b'),
      RegExp(r'\b0[0-9][0-9]{7,8}\b'),
      
      // International format for Malaysian numbers
      RegExp(r'\+60[0-9]{8,10}\b'),
      
      // General formats
      RegExp(r'\b\d{10}\b'),
      RegExp(r'\b\d{3}-\d{3}-\d{4}\b'),
      RegExp(r'\b\d{3} \d{3} \d{4}\b'),
      RegExp(r'\(\d{3}\) ?\d{3}-\d{4}'),
      RegExp(r'\+\d{1,3} ?\d{3} ?\d{3} ?\d{4}'),
      RegExp(r'\b\d{3}\.\d{3}\.\d{4}\b'),
    ];

    String result = text;
    for (var pattern in phonePatterns) {
      result = result.replaceAllMapped(pattern, (match) => '[phone number removed]');
    }
    return result;
  }

  /// Masks email addresses in text
  static String _maskEmails(String text) {
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    return text.replaceAllMapped(emailPattern, (match) => '[email removed]');
  }

  /// Masks addresses in text
  static String _maskAddresses(String text) {
    // Use the same patterns as in _containsAddress
    final List<RegExp> addressPatterns = [
      // Malaysian address format with postcode
      RegExp(r'\b\d{5}\s+[A-Za-z\s]+\b', caseSensitive: false),
      
      // Common Malaysian address terms
      RegExp(r'\bJalan\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bLorong\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bPersiaran\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bTaman\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      RegExp(r'\bKampung\s+[A-Za-z0-9\s]+\b', caseSensitive: false),
      
      // Malaysian state names followed by Malaysia
      RegExp(r'\b(?:Selangor|Kuala Lumpur|Johor|Penang|Perak|Kedah|Kelantan|Sabah|Sarawak|Melaka|Negeri Sembilan|Pahang|Terengganu|Perlis|Putrajaya|Labuan)[,\s]+Malaysia\b', caseSensitive: false),
      
      // Unit/house number patterns common in Malaysia
      RegExp(r'\bNo\.\s*\d+[A-Za-z]?[,\s]+', caseSensitive: false),
      RegExp(r'\bUnit\s+\d+[A-Za-z]?[,\s]+', caseSensitive: false),
      
      // Common international formats
      RegExp(r'\b\d+\s+[A-Za-z]+\s+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr)\b', caseSensitive: false),
      RegExp(r'\bP\.?O\.?\s*Box\s+\d+\b', caseSensitive: false),
      RegExp(r'\b\d{5}(?:-\d{4})?\b'),
      RegExp(r'\b[A-Za-z\s]+,\s*[A-Z]{2}\b'),
    ];

    String result = text;
    for (var pattern in addressPatterns) {
      result = result.replaceAllMapped(pattern, (match) => '[address removed]');
    }
    return result;
  }
}
