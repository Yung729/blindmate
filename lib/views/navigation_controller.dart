import 'package:blindmate/viewmodels/dataBinding/auth_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/auth_event_handler.dart';
import 'package:blindmate/viewmodels/state/auth_state.dart';
import 'package:blindmate/views/screens/bottle_note_home_screen.dart';
import 'package:blindmate/views/screens/my_bottle_note_screen.dart';
import 'package:blindmate/views/screens/pick_up_screen.dart';
import 'package:blindmate/views/screens/redeem_reward_screen.dart';
import 'package:blindmate/views/screens/send_bottle_note_screen.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/sharing_screen.dart';
import 'screens/do_mission_screen.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  late AuthEventHandler _userEventHandler;

  int _currentIndex = 0;

  // Define the question_circle_fill icon
  static const IconData question_circle_fill = IconData(
    0xf790,
    fontFamily: 'CupertinoIcons',
    fontPackage: 'cupertino_icons',
  );

  @override
  void initState() {
    super.initState();
    final currentUserState = context.read<AuthState>();
    final dataBinding = AuthDataBinding();
    _userEventHandler = AuthEventHandler(currentUserState, dataBinding);
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    await _userEventHandler.fetchUserData(context);
    if (mounted) {
      setState(() {});
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'happy':
        return Icons.sentiment_satisfied_alt;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'fear':
        return Icons.mood_bad;
      case 'disgust':
        return Icons.sick;
      case 'anger':
        return Icons.sentiment_very_dissatisfied;
      case 'surprise':
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.person;
    }
  }

  void _showEmotionPicker(BuildContext context, AuthState authState) {
    final emotions = [
      {
        'label': 'Happy',
        'value': 'happy',
        'icon': Icons.sentiment_satisfied_alt,
      },
      {'label': 'Sad', 'value': 'sad', 'icon': Icons.sentiment_dissatisfied},
      {'label': 'Fear', 'value': 'fear', 'icon': Icons.mood_bad},
      {'label': 'Disgust', 'value': 'disgust', 'icon': Icons.sick},
      {
        'label': 'Anger',
        'value': 'anger',
        'icon': Icons.sentiment_very_dissatisfied,
      },
      {
        'label': 'Surprise',
        'value': 'surprise',
        'icon': Icons.sentiment_very_satisfied,
      },
    ];

    final currentEmotion = authState.currentUser?.emotionStatus;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'How are you feeling?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...emotions.map((emotion) {
                final isSelected = emotion['value'] == currentEmotion;
                return Container(
                  color: isSelected ? Colors.blue.withOpacity(0.15) : null,
                  child: ListTile(
                    leading: Icon(
                      emotion['icon'] as IconData,
                      color: isSelected ? Colors.blue : null,
                    ),
                    title: Text(
                      emotion['label'] as String,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final handler = AuthEventHandler(
                        authState,
                        AuthDataBinding(),
                      );
                      await handler.onEmotionSelected(
                        context,
                        emotion['value'] as String,
                      );
                      setState(() {}); // Refresh UI if needed
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Method to show the "Survey & Chat FAQ" dialog
  void _showLevelGuidanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Survey & Chat FAQ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learn how to boost your level with these FAQs!',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              // FAQ 1
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. What is the purpose of the Survey and Chat features?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'These features are designed to assess your activity quality and engagement. Both use Gemini moderation service to generate a weekly score that reflects your interactions and responses.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // FAQ 2
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2. How are the scores calculated?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Gemini moderation service analyzes your survey responses and chat behavior to generate a score for each. These scores are based on relevance, clarity, positivity, and overall interaction quality. The chat score during your chat needs to be close to your survey score (Difference score < 0.3).',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // FAQ 3
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3. How does the level system work?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Each week, your survey score is matched against your chat score. If both scores align (i.e., meet a certain internal consistency), your user level increases, based on a proprietary algorithm.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // FAQ 4
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4. What happens if the scores don’t match?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'If your scores show inconsistency, your level may remain the same or increase more slowly (both scores do not differ too much). Consistency encourages authentic and meaningful participation.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // FAQ 5
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '5. What are the benefits of leveling up?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Higher levels unlock better rewards when completing missions.\n'
                          'Level < 10: You receive standard rewards (e.g., 100 fragments).\n'
                          'Level ≥ 10: You start receiving bonus rewards (e.g., 120 fragments or more).\n'
                          'The higher your level, the greater the bonus.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // FAQ 6
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '6. How often can I take the survey?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'The survey is available weekly. You need to complete it once per week to participate in the score matching process.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // FAQ 7
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '7. Can my level decrease?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'No, your level does not decrease, but your will stop there if your scores are inconsistent or if you skip weekly surveys.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // FAQ 8
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '8. Is there any other way to increase level?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Yes, you can gain extra level when the people whom you chat with sent you flower. Your level will be added.\n'
                          'Engage in meaningful and respectful chats.\n'
                          'Stay active consistently every week.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the guidance dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Got It',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserState = context.watch<AuthState>();

    if (currentUserState.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> screens = [
      const HomeScreen(),
      SharingScreen(
        userId: currentUserState.currentUser!.userId,
        userName: currentUserState.currentUser!.name,
        avatarImg: currentUserState.currentUser!.avatarImg,
      ),
      DoMissionScreen(user: currentUserState.currentUser!),
      const BottleNoteHomeScreen(),
      const PickUpScreen(),
      const SendBottleNoteScreen(),
      const MyBottleNotesScreen(),
      RedeemRewardScreen(user: currentUserState.currentUser!),
    ];

    return Scaffold(
      body: Stack(
        children: [
          screens[_currentIndex],
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 80,
              title:
                  _currentIndex == 0
                      ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap:
                                  () => _showEmotionPicker(
                                    context,
                                    currentUserState,
                                  ),
                              child: Icon(
                                _getEmotionIcon(
                                  currentUserState.currentUser!.emotionStatus,
                                ),
                                color: Colors.black,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Level ${currentUserState.currentUser!.levelValue}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 150,
                                  child: LinearPercentIndicator(
                                    percent:
                                        currentUserState
                                            .currentUser!
                                            .progressionValue,
                                    backgroundColor: Colors.grey[300],
                                    progressColor: Colors.blue,
                                    lineHeight: 6.0,
                                    animation: true,
                                    animationDuration: 1000,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.black),
                  onPressed: () => _userEventHandler.onLogoutPressed(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Sharing'),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: 'Mission',
          ),
        ],
      ),
    );
  }
}
