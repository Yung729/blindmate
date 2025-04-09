import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pick_up_screen.dart';
import '../../models/dataModels/bottle_note_model.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/state/home_state.dart';

class ShowBottleNoteScreen extends StatefulWidget {
  final BottleNote note;

  const ShowBottleNoteScreen({super.key, required this.note});

  @override
  State<ShowBottleNoteScreen> createState() => _ShowBottleNoteScreenState();
}

class _ShowBottleNoteScreenState extends State<ShowBottleNoteScreen> {
  final TextEditingController _replyController = TextEditingController();
  late BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    _eventHandler = BottleNoteEventHandler(
      state: context.read<BottleNoteState>(),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _replyToNote() async {
    final user = context.read<HomeState>().currentUser;
    final replyText = _replyController.text.trim();

    if (user == null || replyText.isEmpty) return;

    try {
      await _eventHandler.replyToNote(
        noteId: widget.note.noteId,
        userId: user.userId,
        content: replyText,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Reply sent!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send reply: $e")));
      }
    } finally {
      _replyController.clear();
    }
  }

  void _showReplyDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop(); // Dismiss when tapping outside
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap inside dialog from dismissing it
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(200, 243, 255, 1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _replyController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Write something to reply",
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            // TODO: Open sticker picker
                          },
                          icon: const Icon(
                            Icons.emoji_emotions,
                            color: Colors.black,
                          ),
                          label: const Text(
                            "Add Stickers",
                            style: TextStyle(color: Colors.black),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final replyText = _replyController.text.trim();
                          if (replyText.isNotEmpty) {
                            _replyToNote();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        child: const Text("Reply Bottle Note"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bottlenote_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.note.content,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _showReplyDialog,
                  child: const Text("Reply"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PickUpScreen()),
                    );
                  },
                  child: const Text("Pick Up Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
