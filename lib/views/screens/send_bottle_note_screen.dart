import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import 'bottle_note_home_screen.dart';
import '../UIComponents/custom_snackbar.dart';

class SendBottleNoteScreen extends StatefulWidget {
  final String? content;

  const SendBottleNoteScreen({super.key, this.content});

  @override
  State<SendBottleNoteScreen> createState() => _SendBottleNoteScreenState();
}

class _SendBottleNoteScreenState extends State<SendBottleNoteScreen>
    with SingleTickerProviderStateMixin {
  late final BottleNoteEventHandler _eventHandler;
  late AnimationController _animationController;
  late Animation<double> _swingAnimation;

  @override
  void initState() {
    super.initState();

    _eventHandler = BottleNoteEventHandler(
      state: context.read<BottleNoteState>(),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendBottleNote();
    });
  }

  Future<void> _sendBottleNote() async {
    final user = context.read<AuthState>().currentUser;

    if (user == null) {
      CustomSnackBar.show(
        context: context,
        message: "Failed to fetch user data!",
        status: 'ERROR',
      );
      await Future.delayed(const Duration(seconds: 3));
      Navigator.pop(context);
      return;
    }

    if (!mounted) {
      CustomSnackBar.show(
        context: context,
        message: "Bottle Note failed to send!\nPlease try again later.",
        status: 'ERROR',
      );
      await Future.delayed(const Duration(seconds: 3));
      Navigator.pop(context);
      return;
    }

    try {
      // Check content moderation first
      await _eventHandler.sendNote(
        content: widget.content!,
        userId: user.userId,
      );

      if (mounted) {
        String message;
        if (_eventHandler.state.lastNoteStatus == 'SAFE') {
          message =
              "✅ Your bottle note has been sent! You will be redirected in 3 seconds";
        } else if (_eventHandler.state.lastNoteStatus == 'WARNING') {
          message =
              "⚠️ Your bottle note has been sent, but contains sensitive content. You will be redirected in 3 seconds";
        } else if (_eventHandler.state.lastNoteStatus == 'UNSAFE') {
          message =
              "❌ Your message was blocked due to inappropriate content. You will be redirected in 3 seconds";
        } else {
          message = "❌ Failed to send bottle note! Please try again later";
        }
        CustomSnackBar.show(
          context: context,
          message: message,
          status: _eventHandler.state.lastNoteStatus,
        );

        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottleNoteHomeScreen()),
          (route) => route.isFirst,
        );
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                    const Spacer(),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Your message has set sail! \uD83C\uDF0A\uD83D\uDCDC\nSomeone, somewhere will find it soon',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 2, color: Colors.black45),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _swingAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _swingAnimation.value,
                          child: Image.asset('assets/bottle.png', height: 120),
                        );
                      },
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
