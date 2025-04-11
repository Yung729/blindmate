import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final user = context.read<AuthState>().currentUser;
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

  Future<void> _showNoteDialog(BottleNote note) async {
    final replies = await _eventHandler.getRepliesForNote(note.noteId);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Bottle Note"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.content),
                  const SizedBox(height: 16),
                  const Text(
                    "Replies:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...replies.asMap().entries.map((entry) {
                    final i = entry.key + 1; // Start from 1
                    final reply = entry.value;
                    return ListTile(
                      title: Text("Reply $i"),
                      subtitle: Text(reply.content),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/bottlenote_bg.png', fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "My Bottle Notes",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _myNotes.isEmpty
                          ? const Center(
                            child: Text("You haven't written any notes yet."),
                          )
                          : ListView.builder(
                            itemCount: _myNotes.length,
                            itemBuilder: (context, index) {
                              final note = _myNotes[index];
                              return GestureDetector(
                                onTap: () => _showNoteDialog(note),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.content,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: CustomButton(
                                          text: 'Remove',
                                          onPressed: () {
                                            _deleteNote(note.noteId);
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          backgroundColor: Colors.red,
                                          horizontalPadding: 20,
                                          verticalPadding: 10,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
