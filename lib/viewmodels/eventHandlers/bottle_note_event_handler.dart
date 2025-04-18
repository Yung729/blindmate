import '../../models/dataModels/bottle_note_model.dart';
import '../state/bottle_note_state.dart';
import '../dataBinding/bottle_note_data_binding.dart';
import '../../models/dataModels/reply_model.dart';
import 'package:flutter/foundation.dart';

class BottleNoteEventHandler {
  final BottleNoteState state;
  final BottleNoteDataBinding dataBinding;

  BottleNoteEventHandler({required this.state})
    : dataBinding = BottleNoteDataBinding(bottleNoteState: state);

  Future<void> init() async {
    await dataBinding.initialize();
  }

  Future<void> loadNotes() async {
    await dataBinding.loadNotes();
  }

  Future<void> pickRandomNote(String userId) async {
    await loadNotes();
    final allNotes = state.notes;

    // Get all replies for the current user
    final userReplies = <String, bool>{};
    for (final note in allNotes) {
      try {
        final replies = await dataBinding.getRepliesForNote(note.noteId);
        if (replies.any((reply) => reply.responderId == userId)) {
          userReplies[note.noteId] = true;
        }
      } catch (e) {
        debugPrint("❌ Error checking replies for note ${note.noteId}: $e");
      }
    }

    final validNotes =
        allNotes.where((note) {
          // Filter out notes that:
          // 1. Were sent by the current user
          // 2. Have expired
          // 3. Have been replied to by the current user
          return note.senderId != userId &&
              note.expirationTime.isAfter(DateTime.now()) &&
              !userReplies.containsKey(note.noteId);
        }).toList();

    if (validNotes.isEmpty) {
      state.clearPickedNote();
      return;
    }

    validNotes.shuffle();
    state.setPickedNote(validNotes.first);
  }

  Future<void> sendNote({
    required String content,
    required String userId,
  }) async {
    try {
      await dataBinding.sendNote(userId, content);
    } catch (e) {
      if (e.toString().contains("BANNED")) {
        throw Exception("BANNED");
        // return;
      }
      rethrow;
    }
  }

  Future<void> replyToNote({
    required String noteId,
    required String userId,
    required String content,
  }) async {
    final replies = await dataBinding.getRepliesForNote(noteId);
    if (replies.any((reply) => reply.responderId == userId)) {
      throw Exception("You have already replied to this note");
    }
    try {
      await dataBinding.replyToNote(noteId, userId, content);
      // return 'SAFE';
    } catch (e) {
      if (e.toString().contains("UNSAFE")) {
        // return 'UNSAFE';
      }
      rethrow;
    }
  }

  Future<List<Reply>> getRepliesForNote(String noteId) async {
    return await dataBinding.getRepliesForNote(noteId);
  }

  Future<List<BottleNote>> getNotesByUserId(String userId) async {
    return await dataBinding.getNotesByUserId(userId);
  }

  Future<void> deleteNote(String noteId) async {
    await dataBinding.deleteNote(noteId);
  }

  void dispose() {
    // Clean up any resources if needed
  }
}
