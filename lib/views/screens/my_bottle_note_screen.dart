import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../viewmodels/state/do_mission_state.dart';
import '../UIComponents/custom_dialog.dart';
import '../UIComponents/custom_snackbar.dart';

class MyBottleNotesScreen extends StatefulWidget {
  const MyBottleNotesScreen({super.key});

  @override
  State<MyBottleNotesScreen> createState() => _MyBottleNotesScreenState();
}

class _MyBottleNotesScreenState extends State<MyBottleNotesScreen> {
  late final BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    final state = context.read<BottleNoteState>();
    _eventHandler = BottleNoteEventHandler(
      state: state,
      missionState: context.read<MissionState>(),
    );
    _loadMyNotes();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMyNotes() async {
    final user = context.read<AuthState>().currentUser;
    if (user == null) return;

    try {
      final notes = await _eventHandler.getNotesByUserId(user.userId);
      _eventHandler.state.setNotes(notes);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "❌ Failed to load notes: ${e.toString()}",
          status: 'ERROR',
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final shouldDelete = await showConfirmDialog(
      context,
      "Delete Note",
      "Are you sure you want to delete this note permanently? This action cannot be undone.",
    );

    if (!shouldDelete) return;

    try {
      await _eventHandler.deleteNote(noteId);
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "✅ Note deleted",
          status: 'SAFE',
        );
        _loadMyNotes();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "❌ Failed to delete note: ${e.toString()}",
          status: 'ERROR',
        );
      }
    }
  }

  Future<void> _showNoteDialog(final note) async {
    try {
      final replies = await _eventHandler.getRepliesForNote(note.noteId);
      if (!mounted) return;

      await showCustomDialog(
        context: context,
        title: "Bottle Note",
        backgroundColor: Colors.lightBlue.shade50,
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (replies.isEmpty)
                  const Text(
                    "No replies yet",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  )
                else ...[
                  const Text(
                    "Replies:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...replies.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final reply = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        "Reply $i: ${reply.content}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
        barrierDismissible: true,
      );
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "❌ Failed to load replies: ${e.toString()}",
          status: 'ERROR',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                        onPressed: () => Navigator.pop(context),
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
                  child: Consumer<BottleNoteState>(
                    builder: (context, state, child) {
                      return state.notes.isEmpty
                          ? const Center(
                            child: Text(
                              "No notes yet",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.notes.length,
                            itemBuilder: (context, index) {
                              final note = state.notes[index];
                              return Card(
                                color: Colors.lightBlue.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            note.content,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "Status: ${note.status == 'INACTIVE' ? 'Expired' : 'Available'}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          CustomButton(
                                            text: 'View Replies',
                                            onPressed:
                                                () => _showNoteDialog(note),
                                            backgroundColor: Colors.blue[400],
                                            horizontalPadding: 20,
                                            verticalPadding: 10,
                                            fontSize: 12,
                                          ),
                                          const SizedBox(width: 8),
                                          CustomButton(
                                            text: 'Remove',
                                            onPressed:
                                                () => _deleteNote(note.noteId),
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                            backgroundColor: Colors.red[400],
                                            horizontalPadding: 20,
                                            verticalPadding: 10,
                                            fontSize: 12,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
