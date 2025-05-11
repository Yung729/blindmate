import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pick_up_screen.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../UIComponents/custom_button.dart';
import '../UIComponents/custom_snackbar.dart';
import '../UIComponents/custom_dialog.dart';
import 'bottle_note_home_screen.dart';

class ShowBottleNoteScreen extends StatefulWidget {
  final note;

  const ShowBottleNoteScreen({super.key, required this.note});

  @override
  State<ShowBottleNoteScreen> createState() => _ShowBottleNoteScreenState();
}

class _ShowBottleNoteScreenState extends State<ShowBottleNoteScreen> {
  final TextEditingController _replyController = TextEditingController();
  late final BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    _eventHandler = BottleNoteEventHandler(
      state: context.read<BottleNoteState>(),
      missionState: context.read<MissionState>(),
    );
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    try {
      final replies = await _eventHandler.getRepliesForNote(widget.note.noteId);
      _eventHandler.state.setReplies(replies);
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
  void dispose() {
    _replyController.dispose();
    _eventHandler.dispose();
    super.dispose();
  }

  void _replyToNote() async {
    final user = context.read<AuthState>().currentUser;
    final replyText = _replyController.text.trim();

    if (user == null || replyText.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _eventHandler.replyToNote(
        noteId: widget.note.noteId,
        userId: user.userId,
        content: replyText,
      );

      Navigator.pop(context);

      if (!mounted) return;

      String message;
      String? result = _eventHandler.state.lastNoteStatus;
      switch (result) {
        case 'SAFE':
          message = "✅ Reply sent!";
          await _loadReplies();
          break;
        case 'WARNING':
          message = "⚠️ Reply sent, but it contains sensitive content.";
          await _loadReplies();
          break;
        case 'UNSAFE':
          message = "❌ Reply blocked due to inappropriate content.";
          break;
        default:
          message = "❌ Failed to send bottle note! Please try again later.";
      }

      Navigator.of(context).pop();
      CustomSnackBar.show(context: context, message: message, status: result);
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "❌ Error: ${e.toString()}",
          status: 'ERROR',
        );
      }
    } finally {
      _replyController.clear();
    }
  }

  void _showReplyDialog() {
    showCustomDialog(
      context: context,
      title: "Reply to Bottle Note",
      backgroundColor: const Color.fromRGBO(200, 243, 255, 1),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottleNoteHomeScreen()),
          (route) => route.isFirst,
        );
        return false;
      },
      child: Scaffold(
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
                        (route) => route.isFirst,
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
                        child: Consumer<BottleNoteState>(
                          builder: (context, state, child) {
                            return Column(
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
                                const SizedBox(height: 20),
                                if (state.replies.isEmpty)
                                  const Text(
                                    "No replies yet",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Replies:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...state.replies.asMap().entries.map((
                                        entry,
                                      ) {
                                        final i = entry.key + 1;
                                        final reply = entry.value;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Text(
                                            "Reply $i: ${reply.content}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                              ],
                            );
                          },
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
                  CustomButton(text: 'Reply', onPressed: _showReplyDialog),
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
      ),
    );
  }
}
