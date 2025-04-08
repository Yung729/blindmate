import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/bottle_note_model.dart';
import '../models/dataModels/reply_model.dart';

class BottleNoteService {
  final _firestore = FirebaseFirestore.instance;
  final _notesRef = FirebaseFirestore.instance.collection('bottleNotes');

  Future<void> addNote(BottleNote note) async {
    await _notesRef.doc(note.noteId).set(note.toJson());
  }

  Future<void> addReply(String noteId, Reply reply) async {
    await _notesRef
        .doc(noteId)
        .collection('replies')
        .doc(reply.replyId)
        .set(reply.toJson());
  }

  Future<List<BottleNote>> getAllNotes() async {
    final querySnapshot = await _notesRef.get();
    return Future.wait(
      querySnapshot.docs.map((doc) async {
        final data = doc.data();
        final repliesSnapshot = await doc.reference.collection('replies').get();
        final replies =
            repliesSnapshot.docs.map((r) => Reply.fromJson(r.data())).toList();

        return BottleNote.fromJson({...data, 'replies': replies});
      }),
    );
  }

  Future<BottleNote?> getNote(String noteId) async {
    final doc = await _notesRef.doc(noteId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final repliesSnapshot = await doc.reference.collection('replies').get();
    final replies =
        repliesSnapshot.docs.map((r) => Reply.fromJson(r.data())).toList();

    return BottleNote.fromJson({...data, 'replies': replies});
  }
}
