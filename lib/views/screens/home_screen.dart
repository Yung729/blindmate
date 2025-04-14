import 'package:blindmate/viewmodels/dataBinding/auth_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/auth_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'matching_screen.dart';
import 'bottle_note_home_screen.dart';
import '../UIComponents/custom_button.dart';
import 'survey.dart'; // Import for SurveyPage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthState authState;

  @override
  void initState() {
    super.initState();
    authState = context.read<AuthState>();
  }

  void _startRandomMatching() {
    final currentUser = authState.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchingScreen(user: currentUser),
        ),
      );
    }
  }

  void _goToSurvey() {
    final user = authState.currentUser;
    if (authState.currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SurveyPage(userId: user!.userId),
        ),
      ).then((_) async {
        // 🔄 Refresh user data after returning from SurveyPage
        final eventHandler = AuthEventHandler(authState, AuthDataBinding());
        await eventHandler.fetchUserData(context);
        if (mounted) setState(() {}); // Rebuild UI
      });
    } else {
      // Handle the case where currentUser is null
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
    }
  }

  void _showSurveyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Survey Invitation'),
            content: const Text(
              'Would you like to answer survey question?\nNote: It may increase your level.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _goToSurvey(); // Navigate to SurveyPage
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset('assets/bottlenote_bg.png', fit: BoxFit.cover),
          ),

          // Main Content
          SafeArea(
            child: Consumer<AuthState>(
              builder: (context, authState, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: Center(
                        child: Image.asset('assets/logo.png', height: 160),
                      ),
                    ),

                    Column(
                      children: [
                        if (authState.currentUser != null)
                          Text(
                            "Welcome, ${authState.currentUser!.name}!",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black),
                              ],
                            ),
                          )
                        else
                          const CircularProgressIndicator(),
                        const SizedBox(height: 30),
                        CustomButton(
                          text: "Start Matching",
                          onPressed: _startRandomMatching,
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          text: "Survey",
                          onPressed: _showSurveyDialog,
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Column(
                        children: [
                          Image.asset('assets/bottle.png', height: 100),
                          const SizedBox(height: 10),
                          CustomButton(
                            text: "Bottle Note",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const BottleNoteHomeScreen(),
                                ),
                              );
                            },
                            horizontalPadding: 40,
                            verticalPadding: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
