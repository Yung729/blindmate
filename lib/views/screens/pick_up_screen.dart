import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import 'package:lottie/lottie.dart';
import 'show_bottle_note_content_screen.dart';
import 'bottle_note_home_screen.dart';

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
    final user = context.read<AuthState>().currentUser;
    if (user == null) return;

    await _eventHandler.pickRandomNote(user.userId);
    final pickedNote = context.read<BottleNoteState>().pickedNote;

    if (!mounted) return;

    if (pickedNote != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bottle Note Found!.\nYou will be redirect in 3 seconds",
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 3));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShowBottleNoteScreen(note: pickedNote),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No available note to pick!")),
      );
      await Future.delayed(const Duration(seconds: 5));
      Navigator.pop(context);
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
                CustomButton(
                  text: 'Cancel Pick Up',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BottleNoteHomeScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
