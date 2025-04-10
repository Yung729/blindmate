import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/home_state.dart';
import '../../viewmodels/dataBinding/current_user_data_binding.dart';
import '../../viewmodels/eventHandlers/home_event_handler.dart';
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
  late HomeEventHandler _homeEventHandler;

  @override
  void initState() {
    super.initState();
    final homeState = context.read<HomeState>();
    final dataBinding = CurrentUserDataBinding();
    _homeEventHandler = HomeEventHandler(
      homeState: homeState,
      dataBinding: dataBinding,
    );
    _homeEventHandler.loadUserData();
  }

  void _startRandomMatching() {
    final currentUser = context.read<HomeState>().currentUser;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyPage(),
      ),
    );
  }

  void _showSurveyDialog() { // New method to show the dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Survey Invitation'),
        content: Text(
          'Would you like to answer survey question?\nNote: It may increase your level.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _goToSurvey(); // Navigate to SurveyPage
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset('assets/bottlenote_bg.png', fit: BoxFit.cover),
          ),

          // Main Content
          SafeArea(
            child: Consumer<HomeState>(
              builder: (context, homeState, child) {
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
                        if (homeState.currentUser != null)
                          Text(
                            "Welcome, ${homeState.currentUser!.name}!",
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
                        const SizedBox(height: 20), // Add spacing between buttons
                        CustomButton(
                          text: "Survey", // Changed text to "Survey"
                          onPressed: _showSurveyDialog, // Show dialog instead of direct navigation
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