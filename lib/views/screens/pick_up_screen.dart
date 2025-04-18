import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/UIComponents/custom_snackbar.dart';
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
  late final BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();
    final state = context.read<BottleNoteState>();
    _eventHandler = BottleNoteEventHandler(state: state);
    _pickRandomNote();
  }

  Future<void> _pickRandomNote() async {
    try {
      final user = context.read<AuthState>().currentUser;
      if (user == null) {
        throw Exception("User not found");
      }

      await _eventHandler.pickRandomNote(user.userId);
      final pickedNote = _eventHandler.state.pickedNote;

      if (pickedNote != null) {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: "Bottle Note Found!\nYou will be redirected in 3 seconds",
            status: 'SUCCESS',
          );
          await Future.delayed(const Duration(seconds: 3));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowBottleNoteScreen(note: pickedNote),
            ),
          );
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: "No available note to pick!",
            status: 'ERROR',
          );
          await Future.delayed(const Duration(seconds: 3));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const BottleNoteHomeScreen(),
            ),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "❌ Error: ${e.toString()}",
          status: 'ERROR',
        );
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pop(context);
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
              mainAxisSize: MainAxisSize.max,
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
                  onPressed:
                      () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BottleNoteHomeScreen(),
                        ),
                        (route) => route.isFirst,
                      ),                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

