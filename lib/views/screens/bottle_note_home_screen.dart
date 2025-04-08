import 'package:blindmate/views/screens/pick_up_screen.dart';
import 'package:blindmate/views/screens/send_bottle_note_screen.dart';
import 'package:blindmate/views/screens/my_bottle_note_screen.dart';
import 'package:flutter/material.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/dataBinding/bottle_note_data_binding.dart';
import 'package:provider/provider.dart';

class BottleNoteHomeScreen extends StatefulWidget {
  const BottleNoteHomeScreen({super.key});

  @override
  State<BottleNoteHomeScreen> createState() => _BottleNoteHomeScreenState();
}

class _BottleNoteHomeScreenState extends State<BottleNoteHomeScreen>
    with WidgetsBindingObserver {
  late BottleNoteDataBinding _dataBinding;
  late BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    _dataBinding = BottleNoteDataBinding();
    final state = context.read<BottleNoteState>();
    _eventHandler = BottleNoteEventHandler(state: state);
  }

  @override
  void dispose() {
    _dataBinding.dispose();
    super.dispose();
  }
  // void _sendBottleNote() async {
  //   final user = context.read<HomeState>().currentUser;
  //   if (user == null || _dataBinding.contentController.text.isEmpty) return;

  //   await _eventHandler.sendNote(
  //     content: _dataBinding.contentController.text,
  //     userId: user.userId,
  //     sticker: _dataBinding.selectedSticker,
  //   );
  //   _dataBinding.clear();
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(const SnackBar(content: Text("Bottle note sent!")));
  // }

  // void _pickUpNote() async {
  //   final user = context.read<HomeState>().currentUser;
  //   if (user == null) return;

  //   await _eventHandler.pickRandomNote(user.userId);
  //   final pickedNote = context.read<BottleNoteState>().pickedNote;
  //   if (pickedNote != null) {
  //     _showReplyDialog(pickedNote);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("No available note to pick!")),
  //     );
  //   }
  // }

  // void _showReplyDialog(BottleNote note) {
  //   final replyController = TextEditingController();
  //   final user = context.read<HomeState>().currentUser;

  //   final hasReplied = note.replies.any((r) => r.responderId == user?.userId);

  //   if (hasReplied) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("You’ve already replied to this note.")),
  //     );
  //     return;
  //   }

  //   showDialog(
  //     context: context,
  //     builder:
  //         (_) => AlertDialog(
  //           title: const Text("Reply to this note"),
  //           content: TextField(
  //             controller: replyController,
  //             decoration: const InputDecoration(
  //               hintText: "Write your reply...",
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () async {
  //                 if (replyController.text.isNotEmpty && user != null) {
  //                   await _eventHandler.replyToNote(
  //                     noteId: note.noteId,
  //                     userId: user.userId,
  //                     content: replyController.text,
  //                   );
  //                   Navigator.pop(context);
  //                   ScaffoldMessenger.of(
  //                     context,
  //                   ).showSnackBar(const SnackBar(content: Text("Reply sent")));
  //                 }
  //               },
  //               child: const Text("Send"),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bottlenote_bg.png', fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyBottleNotesScreen()),
                          );
                        },
                        icon: const Icon(
                          Icons.note_alt_outlined,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'My Note',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _dataBinding.contentController,
                          maxLines: 4,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'Write something about you...',
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            // select sticker
                          },
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          label: const Text('Add Sticker'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), 
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SendBottleNoteScreen(
                                content: _dataBinding.contentController.text,
                                sticker: _dataBinding.selectedSticker,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Send Bottle Note'),
                  ),
                  const SizedBox(height: 60), 
                  Image.asset(
                    'assets/bottle.png', 
                    height: 100, 
                  ),
                  const SizedBox(height: 20), 
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PickUpScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Pick Up'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
