import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/home_state.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../models/dataModels/bottle_note_model.dart';

class MyBottleNotesScreen extends StatefulWidget {
  const MyBottleNotesScreen({super.key});

  @override
  State<MyBottleNotesScreen> createState() => _MyBottleNotesScreenState();
}

class _MyBottleNotesScreenState extends State<MyBottleNotesScreen> {
  late BottleNoteEventHandler _eventHandler;
  List<BottleNote> _myNotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<BottleNoteState>();
    _eventHandler = BottleNoteEventHandler(state: state);
    _loadMyNotes();
  }

  Future<void> _loadMyNotes() async {
    final user = context.read<HomeState>().currentUser;
    if (user == null) return;

    final notes = await _eventHandler.getNotesByUserId(user.userId);
    setState(() {
      _myNotes = notes;
      _loading = false;
    });
  }

  Future<void> _deleteNote(String noteId) async {
    await _eventHandler.deleteNote(noteId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Note deleted")));
    _loadMyNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Notes")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _myNotes.isEmpty
              ? const Center(child: Text("You haven't written any notes yet."))
              : ListView.builder(
                itemCount: _myNotes.length,
                itemBuilder: (context, index) {
                  final note = _myNotes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(note.content),
                      subtitle: Text("Sent at: ${note.timestamp.toLocal()}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNote(note.noteId),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
