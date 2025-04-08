import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/home_state.dart';
import '../../viewmodels/state/bottle_note_state.dart';
import '../../viewmodels/eventHandlers/bottle_note_event_handler.dart';
import '../../viewmodels/dataBinding/bottle_note_data_binding.dart';
import 'bottle_note_home_screen.dart';

class SendBottleNoteScreen extends StatefulWidget {
  final String? content;
  final String? sticker;

  const SendBottleNoteScreen({super.key, this.content, this.sticker});

  @override
  State<SendBottleNoteScreen> createState() => _SendBottleNoteScreenState();
}

class _SendBottleNoteScreenState extends State<SendBottleNoteScreen> {
  late final BottleNoteDataBinding _dataBinding;
  late final BottleNoteEventHandler _eventHandler;

  @override
  void initState() {
    super.initState();

    _dataBinding = BottleNoteDataBinding();
    _eventHandler = BottleNoteEventHandler(
      state: context.read<BottleNoteState>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendBottleNote();
    });
  }

  Future<void> _sendBottleNote() async {
    final user = context.read<HomeState>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch user data!")),
      );
    } else if (widget.content?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bottle Note cannot be empty!\nPlease write a message!")),
      );
    } else if (!mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bottle Note failed to send!\nPlease try again later."),
        ),
      );
    } else {
      await _eventHandler.sendNote(
        content: widget.content!,
        userId: user.userId,
        sticker: widget.sticker,
      );

      _dataBinding.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bottle Note sent!")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottleNoteHomeScreen()),
      );
    }
    await Future.delayed(const Duration(seconds: 5));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _dataBinding.dispose();
    super.dispose();
  }

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
                    ],
                  ),
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
                        shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Image.asset('assets/bottle.png', height: 120),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
