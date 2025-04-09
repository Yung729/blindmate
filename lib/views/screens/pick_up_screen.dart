import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/home_state.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../models/dataModels/bottle_note_model.dart';
import 'package:lottie/lottie.dart';
import 'show_bottle_note_content_screen.dart';

class PickUpScreen extends StatefulWidget {
  const PickUpScreen({super.key});

  @override
  State<PickUpScreen> createState() => _PickUpScreenState();
}

class _PickUpScreenState extends State<PickUpScreen> {
  late BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    _eventHandler = BottleNoteEventHandler(
      state: context.read<BottleNoteState>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickUpNote();
    });
  }

  void _pickUpNote() async {
    final user = context.read<HomeState>().currentUser;
    if (user == null) return;

    await _eventHandler.pickRandomNote(user.userId);
    final pickedNote = context.read<BottleNoteState>().pickedNote;

    if (!mounted) return;

    if (pickedNote != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bottle Note Found!.\nYou will be redirect in 3 seconds")));
      await Future.delayed(const Duration(seconds: 3));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShowBottleNoteScreen(note: pickedNote),
        ),
      );
      // _showReplyDialog(pickedNote);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No available note to pick!")),
      );
      await Future.delayed(const Duration(seconds: 5));
      Navigator.pop(context);
    }
  }

  void _showReplyDialog(BottleNote note) {
    final replyController = TextEditingController();
    final user = context.read<HomeState>().currentUser;

    // final allReplies = _eventHandler.fetchReplies(note.replies);
    // final hasReplied = allReplies.any((r) => r.responderId == user?.userId);

    // // final hasReplied = _eventHandler.fetchReplies(note.replies);

    // // final hasReplied = note.replies.any((r) => r.responderId == user?.userId);

    // // final hasReplied = note.replies.any((r) => r.responderId == user?.userId);

    // if (hasReplied) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("You’ve already replied to this note.")),
    //   );
    //   Navigator.pop(context);
    //   return;
    // }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Reply to this note"),
            content: TextField(
              controller: replyController,
              decoration: const InputDecoration(
                hintText: "Write your reply...",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (replyController.text.isNotEmpty && user != null) {
                    await _eventHandler.replyToNote(
                      noteId: note.noteId,
                      userId: user.userId,
                      content: replyController.text,
                    );
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close pick up screen
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Reply sent")));
                  }
                },
                child: const Text("Send"),
              ),
            ],
          ),
    );
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Looking for a Bottle Note ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    AnimatedTextKit(
                      animatedTexts: [
                        TyperAnimatedText(
                          '.....',
                          textStyle: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      repeatForever: true,
                    ),
                  ],
                ),
                Lottie.asset(
                  'assets/pick_up_animation.json',
                  width: 450,
                  height: 450,
                  repeat: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
