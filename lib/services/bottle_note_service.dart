import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/bottle_note_model.dart';
import '../models/dataModels/reply_model.dart';

class BottleNoteService {
  final _notesRef = FirebaseFirestore.instance.collection('bottle_notes');
  final _repliesRef = FirebaseFirestore.instance.collection('replies');

  Future<void> addNote(BottleNote note) async {
    await _notesRef.doc(note.noteId).set(note.toJson());
  }

  Future<void> addReply(String noteId, Reply reply) async {
    await _repliesRef.doc(reply.replyId).set(reply.toJson());
    await _notesRef.doc(noteId).update({
      'replies': FieldValue.arrayUnion([reply.replyId]),
    });
  }

  Future<List<BottleNote>> getAllNotes() async {
    final querySnapshot = await _notesRef.get();
    return querySnapshot.docs
        .map((doc) => BottleNote.fromJson(doc.data()))
        .toList();
  }

  Future<BottleNote?> getNote(String noteId) async {
    final doc = await _notesRef.doc(noteId).get();
    if (!doc.exists) return null;
    return BottleNote.fromJson(doc.data()!);
  }

  Future<List<Reply>> getRepliesForNote(String noteId) async {
    final querySnapshot =
        await _repliesRef.where('noteId', isEqualTo: noteId).get();
    return querySnapshot.docs.map((doc) => Reply.fromJson(doc.data())).toList();
  }

  Future<void> removeNote(String noteId) async {
    // First delete all replies
    final replies = await getRepliesForNote(noteId);
    for (final reply in replies) {
      await _repliesRef.doc(reply.replyId).delete();
    }

    // Then delete the note
    await _notesRef.doc(noteId).delete();
  }

  Future<List<BottleNote>> getNotesByUserId(String userId) async {
    final querySnapshot =
        await _notesRef.where('senderId', isEqualTo: userId).get();
    return querySnapshot.docs
        .map((doc) => BottleNote.fromJson(doc.data()))
        .toList();
  }
}
