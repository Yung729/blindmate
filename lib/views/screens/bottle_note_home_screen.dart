import 'package:blindmate/views/screens/pick_up_screen.dart';
import 'package:blindmate/views/screens/send_bottle_note_screen.dart';
import 'package:blindmate/views/screens/my_bottle_note_screen.dart';
import 'package:flutter/material.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/custom_snackbar.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/uiValidation/bottle_note_validator.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/state/do_mission_state.dart';
import 'package:provider/provider.dart';

const int maxContentLength = 200; // Define the max length as a constant

class BottleNoteHomeScreen extends StatefulWidget {
  const BottleNoteHomeScreen({super.key});

  @override
  State<BottleNoteHomeScreen> createState() => _BottleNoteHomeScreenState();
}

class _BottleNoteHomeScreenState extends State<BottleNoteHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _swingAnimation;
  late TextEditingController _contentController;
  late final BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _eventHandler = BottleNoteEventHandler(
      state: context.read<BottleNoteState>(),
      missionState: context.read<MissionState>(),
    );

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Create swinging animation
    _swingAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load notes when screen is first opened
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      await _eventHandler.loadNotes();
      _eventHandler.state.setNotes(_eventHandler.state.notes);
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

  @override
  void dispose() {
    _animationController.dispose();
    _contentController.dispose();
    _eventHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                          Navigator.pop(
                            context,
                          ); // Go back to the previous screen
                        },
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyBottleNotesScreen(),
                            ),
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
                          controller: _contentController,
                          maxLines: 4,
                          maxLength: maxContentLength,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Write something about you...',
                            border: InputBorder.none,
                            errorText:
                                _contentController.text.length >
                                        maxContentLength
                                    ? 'Maximum character limit exceeded'
                                    : null, // Show error if maxLength is exceeded
                          ),
                          onChanged: (value) {
                            if (value.length > maxContentLength) {
                              FocusScope.of(
                                context,
                              ).unfocus(); // Dismiss the keyboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Maximum character limit exceeded!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Send Bottle Note',
                    onPressed: () {
                      final content = _contentController.text;

                      if (!BottleNoteValidator.isValid(content)) {
                        CustomSnackBar.show(
                          context: context,
                          message: "❌ Bottle Note cannot be empty!",
                          status: 'ERROR',
                        );
                        return;
                      }

                      _contentController.clear();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  SendBottleNoteScreen(content: content),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  AnimatedBuilder(
                    animation: _swingAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _swingAnimation.value,
                        child: Image.asset('assets/bottle.png', height: 100),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: "Pick Up",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PickUpScreen()),
                      );
                    },
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
