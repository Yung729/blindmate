import 'package:blindmate/models/dataModels/pool_model.dart';
import 'package:blindmate/services/bottle_note_service.dart';
import 'package:blindmate/services/gemini_moderation_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/dataModels/bottle_note_model.dart';
import '../../models/dataModels/reply_model.dart';
import '../state/bottle_note_state.dart';

class BottleNoteDataBinding {
  final BottleNoteService _bottleNoteService = BottleNoteService();
  final GeminiModerationService _moderationService = GeminiModerationService();
  final BottleNoteState bottleNoteState;
  String? selectedSticker;
  final Pool _pool = Pool();

  BottleNoteDataBinding({required this.bottleNoteState});

  Future<void> initialize() async {
    await loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final notes = await _bottleNoteService.getAllNotes();
      bottleNoteState.setNotes(notes);
    } catch (e) {
      debugPrint("❌ Failed to load notes: $e");
    }
  }

  Future<void> sendNote(String userId, String content) async {
    if (content.isEmpty) return;

    final moderationResult = await _moderationService.checkContentLevel(
      content,
    );

    bottleNoteState.setLastNoteStatus(moderationResult!);

    if (!['UNSAFE', 'SAFE', 'WARNING'].contains(moderationResult)) {
      throw Exception('Invalid moderation result: $moderationResult');
    }

    if (moderationResult == 'UNSAFE') return;

    final newNote = BottleNote(
      noteId: const Uuid().v4(),
      content: content,
      senderId: userId,
      timestamp: DateTime.now(),
      expirationTime: DateTime.now().add(const Duration(days: 1)),
      status: 'ACTIVE',
      replyIds: [],
    );

    _pool.addNote(newNote);
    await _bottleNoteService.addNote(newNote);
    bottleNoteState.setNotes([...bottleNoteState.notes, newNote]);
  }

  Future<void> replyToNote(String noteId, String userId, String content) async {
    if (content.isEmpty) return;

    final moderationResult = await _moderationService.checkContentLevel(
      content,
    );

    bottleNoteState.setLastNoteStatus(moderationResult!);


    if (!['UNSAFE', 'SAFE', 'WARNING'].contains(moderationResult)) {
      throw Exception('Invalid moderation result: $moderationResult');
    }

    if (moderationResult == 'UNSAFE') return;

    final reply = Reply(
      replyId: const Uuid().v4(),
      noteId: noteId,
      responderId: userId,
      content: content,
      timestamp: DateTime.now(),
    );

    await _bottleNoteService.addReply(noteId, reply);
  }

  Future<List<Reply>> getRepliesForNote(String noteId) async {
    try {
      final note = await _bottleNoteService.getNote(noteId);
      if (note == null) return [];

      final replies = await _bottleNoteService.getRepliesForNote(noteId);
      return replies;
    } catch (e) {
      debugPrint("❌ Failed to get replies: $e");
      return [];
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _bottleNoteService.removeNote(noteId);
      final updatedNotes =
          bottleNoteState.notes.where((note) => note.noteId != noteId).toList();
      bottleNoteState.setNotes(updatedNotes);
    } catch (e) {
      debugPrint("❌ Failed to delete note: $e");
    }
  }

  Future<List<BottleNote>> getNotesByUserId(String userId) async {
    try {
      final notes = await _bottleNoteService.getNotesByUserId(userId);
      return notes;
    } catch (e) {
      debugPrint("❌ Failed to get user notes: $e");
      return [];
    }
  }
}
