import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';
import 'package:blindmate/viewmodels/eventHandlers/mission_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/viewmodels/state/survey_dialog_state.dart';
import 'package:blindmate/viewmodels/dataBinding/survey_dialog_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/auth_event_handler.dart';
import 'package:blindmate/viewmodels/dataBinding/auth_data_binding.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; 
import 'matching_screen.dart';
import 'bottle_note_home_screen.dart';
import '../UIComponents/custom_button.dart';
import '../UIComponents/custom_dialog.dart';
import 'survey.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AuthState authState;
  late final SurveyDialogState _surveyDialogState;
  late final SurveyDialogDataBinding _dataBinding;
  late AnimationController _animationController;
  late Animation<double> _swingAnimation;
  late MissionEventHandler _missionEventHandler;
  late ConfettiController _confettiController; // Controller for confetti
  int? _lastMilestoneLevel; // Track the last milestone level shown

  @override
  void initState() {
    super.initState();
    authState = context.read<AuthState>();
    _surveyDialogState = SurveyDialogState();
    _dataBinding = SurveyDialogDataBinding(surveyDialogState: _surveyDialogState);
    final missionState = context.read<MissionState>();
    _missionEventHandler = MissionEventHandler(missionState: missionState);

    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Initialize animation controller for bottle swing
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Create swinging animation
    _swingAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await init(context);
      await _missionEventHandler.initialize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose(); // Dispose confetti controller
    super.dispose();
  }

  Future<void> init(BuildContext context) async {
    if (!_surveyDialogState.hasShownSurveyDialog && authState.currentUser != null) {
      bool shouldShowDialog =
          await _dataBinding.shouldShowSurveyDialog(authState.currentUser!.userId);
      if (shouldShowDialog) {
        showSurveyDialog(context);
      }
    }
  }

  void goToSurvey(BuildContext context) {
    final UserModel? user = authState.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SurveyPage(userId: user.userId),
        ),
      ).then((_) async {
        // Refresh user data after survey
        final eventHandler = AuthEventHandler(authState, AuthDataBinding());
        await eventHandler.fetchUserData(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  void showSurveyDialog(BuildContext context) {
    final UserModel? user = authState.currentUser;
    if (user != null) {
      _dataBinding.updatePopDialogTimestamp(user.userId);
      showCustomDialog(
        context: context,
        title: 'Survey Invitation',
        content: const Text(
          'Would you like to answer survey question?\nNote: It may increase your level.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              goToSurvey(context);
            },
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }
  }

  void _startRandomMatching() {
    final UserModel? currentUser = authState.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchingScreen(user: currentUser),
        ),
      );
    }
  }

  // Check if the level is a milestone (multiple of 10) and trigger confetti
  void _checkAndTriggerMilestoneAnimation(int currentLevel) {
    if (currentLevel % 10 == 0 && _lastMilestoneLevel != currentLevel) {
      _confettiController.play();
      _lastMilestoneLevel = currentLevel; // Update the last milestone shown
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SurveyDialogState()),
      ],
      child: Scaffold(
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
                  // Check for milestone level when authState updates
                  if (authState.currentUser != null) {
                    final int currentLevel = authState.currentUser!.levelValue ?? 1;
                    _checkAndTriggerMilestoneAnimation(currentLevel);
                  }

                  return Stack(
                    children: [
                      // Centered main content
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            authState.currentUser != null
                                ? Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      image: DecorationImage(
                                        image: authState.currentUser!.avatarImg.isNotEmpty
                                            ? NetworkImage(authState.currentUser!.avatarImg)
                                            : const AssetImage('assets/default_pic.jpg')
                                                as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Image.asset('assets/default_pic.jpg', height: 100),
                            const SizedBox(height: 20),

                            // Welcome text
                            if (authState.currentUser != null)
                              Text(
                                "Welcome, ${authState.currentUser!.name}!",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 97, 95, 95),
                                  shadows: [
                                    Shadow(
                                        blurRadius: 2,
                                        color: Color.fromARGB(255, 135, 90, 90)),
                                  ],
                                ),
                              )
                            else
                              const CircularProgressIndicator(),
                            const SizedBox(height: 20),

                            // Matching button
                            CustomButton(
                              text: "Start Matching",
                              onPressed: _startRandomMatching,
                            ),
                          ],
                        ),
                      ),

                      // Bottom section with bottle (positioned absolutely)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 30,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BottleNoteHomeScreen(),
                              ),
                            );
                          },
                          child: AnimatedBuilder(
                            animation: _swingAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _swingAnimation.value,
                                child: Image.asset(
                                  'assets/bottle.png',
                                  height: 100,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.blue,
                  Colors.white,
                  Colors.lightBlueAccent,
                ],
                numberOfParticles: 30,
                gravity: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}