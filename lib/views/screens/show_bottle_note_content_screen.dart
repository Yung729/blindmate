import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pick_up_screen.dart';
import '../../models/dataModels/bottle_note_model.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../UIComponents/custom_button.dart';
import 'bottle_note_home_screen.dart';
import '../UIComponents/custom_dialog.dart';

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
    final user = context.read<AuthState>().currentUser;
    final replyText = _replyController.text.trim();

    if (user == null || replyText.isEmpty) return;

    // Show loading while checking
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _eventHandler.replyToNote(
        noteId: widget.note.noteId,
        userId: user.userId,
        content: replyText,
      );

      Navigator.pop(context); // Close loading

      if (!mounted) return;

      String message;
      switch (result) {
        case 'SAFE':
          message = "✅ Reply sent!";
          Navigator.of(context).pop(); // Close reply dialog/screen
          break;
        case 'WARNING':
          message = "⚠️ Reply sent, but it contains sensitive content.";
          Navigator.of(context).pop();
          break;
        default:
          message = "❌ Reply blocked due to inappropriate content.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              result!.contains('Warning') ? Colors.orange[400] : Colors.red[400],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(4),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
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
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Reply Bottle Note',
                        onPressed: () {
                          final replyText = _replyController.text.trim();
                          if (replyText.isNotEmpty) {
                            _replyToNote();
                          }
                        },
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
                onPressed:
                    () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BottleNoteHomeScreen(),
                      ),
                      (route) => route.isFirst, // keep the first route only
                    ),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomButton(
                  text: 'Reply',
                  onPressed: () {
                    _showReplyDialog();
                  },
                ),
                CustomButton(
                  text: 'Pick Up Next',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PickUpScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
