import 'package:uuid/uuid.dart';
import '../../models/dataModels/bottle_note_model.dart';
import '../state/bottle_note_state.dart';
import '../../models/dataModels/pool_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dataModels/reply_model.dart';

class BottleNoteEventHandler {
  final BottleNoteState state;

  BottleNoteEventHandler({required this.state});

  Future<void> loadNotes() async {
    await Pool().loadNotesFromFirebase();
    state.setNotes(Pool().notes);
  }

  Future<void> pickRandomNote(String userId) async {
    await loadNotes();
    final allNotes = state.notes;
    final validNotes =
        allNotes.where((note) {
          return note.senderId != userId &&
              note.expirationTime.isAfter(DateTime.now());
        }).toList();
    print(validNotes.length);
    print(validNotes[0].senderId);
    print(validNotes[0].content);
    print(validNotes[0].noteId);

    if (validNotes.isEmpty) {
      state.clearPickedNote();
      return;
    } else {
      state.setNotes(validNotes);
      Pool().clear();
      for (final note in validNotes) {
        Pool().addNote(note);
      }
      state.setPickedNote(Pool().pickRandomNote());
    }
  }

  Future<void> sendNote({
    required String content,
    required String userId,
    String? sticker,
  }) async {
    final newNote = BottleNote(
      noteId: const Uuid().v4(),
      content: content,
      senderId: userId,
      timestamp: DateTime.now(),
      expirationTime: DateTime.now().add(const Duration(days: 1)),
      status: 'active',
      replies: [],
    );

    await FirebaseFirestore.instance
        .collection('bottle_notes')
        .doc(newNote.noteId)
        .set(newNote.toJson());

    Pool().addNote(newNote);
    state.setNotes(Pool().notes);
  }

  Future<void> replyToNote({
    required String noteId,
    required String userId,
    required String content,
  }) async {
    final replyId = const Uuid().v4();
    final now = DateTime.now();

    final reply = Reply(
      replyId: replyId,
      noteId: noteId,
      responderId: userId,
      content: content,
      timestamp: now,
    );

    await FirebaseFirestore.instance
        .collection('replies')
        .doc(replyId)
        .set(reply.toJson());

    await FirebaseFirestore.instance
        .collection('bottle_notes')
        .doc(noteId)
        .update({
          'replies': FieldValue.arrayUnion([replyId]),
        });
  }

  Future<List<Reply>> fetchReplies(List<String> replyIds) async {
    final firestore = FirebaseFirestore.instance;
    List<Reply> replies = [];

    for (String id in replyIds) {
      final doc = await firestore.collection('replies').doc(id).get();
      if (doc.exists) {
        replies.add(Reply.fromJson(doc.data()!));
      }
    }

    return replies;
  }

  Future<List<BottleNote>> getNotesByUserId(String userId) async {
    final CollectionReference notesRef = FirebaseFirestore.instance.collection(
      'bottle_notes',
    );
    final querySnapshot =
        await notesRef
            .where('senderId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return BottleNote.fromJson(data);
    }).toList();
  }

  Future<void> deleteNote(String noteId) async {
    final CollectionReference notesRef = FirebaseFirestore.instance.collection(
      'bottle_notes',
    );
    final noteDoc = notesRef.doc(noteId);

    final repliesSnapshot = await noteDoc.collection('replies').get();
    for (var doc in repliesSnapshot.docs) {
      await doc.reference.delete();
    }

    await noteDoc.delete();
  }
}
