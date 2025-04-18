import 'package:blindmate/views/screens/pick_up_screen.dart';
import 'package:blindmate/views/screens/send_bottle_note_screen.dart';
import 'package:blindmate/views/screens/my_bottle_note_screen.dart';
import 'package:flutter/material.dart';
import '../../viewmodels/dataBinding/bottle_note_data_binding.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'home_screen.dart';
import '../../viewmodels/uiValidation/bottle_note_validator.dart';

class BottleNoteHomeScreen extends StatefulWidget {
  const BottleNoteHomeScreen({super.key});

  @override
  State<BottleNoteHomeScreen> createState() => _BottleNoteHomeScreenState();
}

class _BottleNoteHomeScreenState extends State<BottleNoteHomeScreen>
    with WidgetsBindingObserver {
  late BottleNoteDataBinding _dataBinding;

  @override
  void initState() {
    super.initState();
    _dataBinding = BottleNoteDataBinding();
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
                          Navigator.pop(context); // Go back to the previous screen
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
                          controller: _dataBinding.contentController,
                          maxLines: 4,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'Write something about you...',
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Send Bottle Note',
                    onPressed: () {
                      final content = _dataBinding.contentController.text;

                      if (!BottleNoteValidator.isValid(content)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ Bottle Note cannot be empty!"),
                          ),
                        );
                        return;
                      }

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
                  Image.asset('assets/bottle.png', height: 100),
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
