import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/services/do_mission_service.dart';
import 'package:blindmate/services/survey_service.dart';
import 'package:blindmate/viewmodels/dataBinding/auth_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/auth_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'matching_screen.dart';
import 'bottle_note_home_screen.dart';
import '../UIComponents/custom_button.dart';
import 'survey.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AuthState authState;
  bool _hasShownSurveyDialog = false;
  late AnimationController _animationController;
  late Animation<double> _swingAnimation;
  final SurveyService _dialogService = SurveyService();

  @override
  void initState() {
    super.initState();
    authState = context.read<AuthState>();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Create swinging animation
    _swingAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Check survey dialog status after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_hasShownSurveyDialog && authState.currentUser != null) {
        bool shouldShowDialog = await _dialogService
            .shouldShowSurveyDialog(authState.currentUser!.userId);

        if (shouldShowDialog) {
          _showSurveyDialog();
          _hasShownSurveyDialog = true;
        }

        if ((await fetchMissionsFromFirebase(limit: 1)).isEmpty) {
          await generateAndStoreMissions();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _goToSurvey() {
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
        if (mounted) setState(() {});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  void _showSurveyDialog() {
    final UserModel? user = authState.currentUser;
    if (user != null) {
      _dialogService.showSurveyDialog(context, user.userId, _goToSurvey);
    }
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
                                  Shadow(blurRadius: 2, color: Color.fromARGB(255, 135, 90, 90)),
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
        ],
      ),
    );
  }
}