import 'bottle_note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Pool {
  static final Pool _instance = Pool._internal();

  factory Pool() => _instance;

  Pool._internal();

  final List<BottleNote> _notes = [];

  List<BottleNote> get notes => List.unmodifiable(_notes);

  void addNote(BottleNote note) {
    _notes.add(note);
  }

  Future<void> loadNotesFromFirebase() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('bottle_notes').get();

    clear();
    for (final doc in snapshot.docs) {
      final note = BottleNote.fromJson(doc.data());
      addNote(note);
    }
  }

  BottleNote? pickRandomNote() {
    if (_notes.isEmpty) return null;
    _notes.shuffle();
    return _notes.first;
  }

  void clear() {
    _notes.clear();
  }
}
