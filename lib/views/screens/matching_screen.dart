import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../models/dataModels/user_model.dart';
import '../../viewmodels/state/matching_state.dart';
import '../../viewmodels/dataBinding/matching_data_binding.dart';
import '../../viewmodels/eventHandlers/matching_event_handler.dart';
import '../UIComponents/custom_button.dart';

class MatchingScreen extends StatefulWidget {
  final UserModel user;

  const MatchingScreen({super.key, required this.user});

  @override
  _MatchingScreenState createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with SingleTickerProviderStateMixin {
  late MatchingState _matchingState;
  late MatchingDataBinding _matchingDataBinding;
  late MatchingEventHandler _matchingHandler;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _matchingState = context.read<MatchingState>();
    _matchingDataBinding = MatchingDataBinding(matchingState: _matchingState);
    _matchingHandler = MatchingEventHandler(
      matchingState: _matchingState,
      dataBinding: _matchingDataBinding,
    );

    _initializeMatchingSystem();
    _listenForStateChanges();
  }

  Future<void> _initializeMatchingSystem() async {
    await _matchingHandler.init(widget.user.userId);
    await _matchingHandler.startMatching(widget.user);
  }

  void _listenForStateChanges() {
    _matchingState.addListener(() {
      if (_matchingState.chatRoomId != null && !_isNavigating && mounted) {
        // Move setState outside of the listener callback and into a post-frame callback
        // to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _isNavigating = true;
          });
          _matchingHandler.navigateToChat(
            context,
            _matchingState.chatRoomId!,
            widget.user.userId,
          );
        });
      }
    });
  }

  void _cancelSearch() async {
    await _matchingHandler.cancelMatching(widget.user.userId);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Proper cleanup to avoid memory leaks
    _matchingState.removeListener(_listenForStateChanges);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Sea background image
          Positioned.fill(
            child: Image.asset('assets/sea_background.webp', fit: BoxFit.cover),
          ),
          Center(
            child: Lottie.asset(
              'assets/animated_boat.json',
              width: 500,
              height: 500,
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Finding your match...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(text: "Cancel Matching", onPressed: _cancelSearch),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
