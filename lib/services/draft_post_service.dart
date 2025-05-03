import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing draft posts
class DraftPostService {
  static const String _draftKey = 'post_draft';

  /// Saves post content as a draft
  Future<void> saveDraft({
    required String userId,
    required String content,
    required bool isPublic,
    String? musicUrl,
    String? musicTitle,
    String? linkUrl,
    List<Map<String, dynamic>>? tripJournals,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final draft = {
      'userId': userId,
      'content': content,
      'isPublic': isPublic,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'linkUrl': linkUrl,
      'tripJournals': tripJournals != null
    ? jsonEncode(
        tripJournals.map((journal) {
          final copy = Map<String, dynamic>.from(journal);
          if (copy['date'] is DateTime) {
            copy['date'] = (copy['date'] as DateTime).toIso8601String();
          }
          return copy;
        }).toList(),
      )
    : null,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  /// Gets the saved draft post if any exists
  Future<Map<String, dynamic>?> getDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    
    if (draftJson == null) {
      return null;
    }
    
    try {
      final draft = jsonDecode(draftJson) as Map<String, dynamic>;
      
      // Parse the trip journals if they exist
      if (draft['tripJournals'] != null) {
        final journalsJson = draft['tripJournals'] as String;
        draft['tripJournals'] = List<Map<String, dynamic>>.from(
          (jsonDecode(journalsJson) as List).map((e) {
            final journal = Map<String, dynamic>.from(e);
            if (journal['date'] != null) {
              journal['date'] = DateTime.parse(journal['date']);
            }
            return journal;
          }),
        );
      }
      
      return draft;
    } catch (e) {
      print('Error parsing draft: $e');
      return null;
    }
  }

  /// Clears the saved draft
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  /// Checks if a draft exists
  Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftKey);
  }
}