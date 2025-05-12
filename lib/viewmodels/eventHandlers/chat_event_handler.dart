import 'dart:async';
import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/message_model.dart';
import '../state/chat_state.dart';
import '../dataBinding/chat_data_binding.dart';
import '../uiValidation/chat_validator.dart';
import '../../views/UIComponents/custom_dialog.dart';

class ChatEventHandler {
  final ChatState chatState;
  final ChatDataBinding dataBinding;
  final MatchingEventHandler matchingHandler;

  final String chatRoomId;
  final String currentUserId;

  bool _isChatOpen = true;
  Timer? _inactivityTimer;
  Timer? _typingTimer;
  Timer? _warningTimer;
  Timer? _countdownTimer;
  int _countdownSeconds = 10;
  Timer? _summaryTimer;
  static const int inactivityDurationMinutes = 10;

  StreamSubscription? typingStatusSubscription;
  StreamSubscription? chatUpdatesSubscription;

  // Keep track of when the chat started
  DateTime? _chatStartTime;

  ChatEventHandler({
    required this.chatState,
    required this.dataBinding,
    required this.matchingHandler,
    required this.chatRoomId,
    required this.currentUserId,
  }) {
    _chatStartTime = DateTime.now();
  }

  Future<void> init() async {
    _isChatOpen = true;

    Future.microtask(() {
      dataBinding.clearChatState(); // Reset state when initializing new chat
      dataBinding.setCurrentUserId(currentUserId);
    });

    dataBinding.initialize(chatRoomId, currentUserId);
    await dataBinding.fetchChatPartner(chatRoomId, currentUserId);
    dataBinding.listenTypingStatus(chatRoomId, chatState.otherUserId);
    await dataBinding.loadStickers("happy");
    
    // Set up event listeners
    _setupFlowerEventListener();
  }

  // Setup flower event listener to handle flower animations from the other user
  void _setupFlowerEventListener() {
    // Cancel existing subscription if any
    chatUpdatesSubscription?.cancel();
    
    // Set up listener for flower events
    chatUpdatesSubscription = dataBinding.listenForFlowerEvents(
      chatRoomId,
      _handleFlowerEvent,
    );
  }

  // Handle flower events received from Firestore
  void _handleFlowerEvent(dynamic snapshot) {
    if (snapshot.docs.isNotEmpty) {
      final event = snapshot.docs.first.data() as Map<String, dynamic>;
      if (event['senderId'] != currentUserId) {
        // Show flower animation for the other user
        dataBinding.setShowFlowerAnimation(true);
        Future.delayed(const Duration(seconds: 2), () {
          dataBinding.setShowFlowerAnimation(false);
        });
      }
    }
  }

  // Send a flower to the other user
  Future<int> sendFlower(BuildContext context) async {
    return await dataBinding.sendFlower(
      currentUserId,
      chatRoomId,
      context,
    );
  }

  Future<void> searchStickers(String query) async {
    await dataBinding.loadStickers(query);
  }

  Future<void> sendMessage(
    BuildContext context, {
    String? text,
    String? stickerUrl,
    String? musicUrl,
    String? musicTitle,
  }) async {
    // Validate message has content
    bool hasText = text != null && MessageValidator.isValid(text);
    bool hasSticker = stickerUrl != null && stickerUrl.isNotEmpty;
    bool hasMusic = musicUrl != null && musicUrl.isNotEmpty;
    
    if (!hasText && !hasSticker && !hasMusic) {
      print("❌ Invalid message, no content to send");
      return;
    }

    final message = MessageModel(
      senderId: currentUserId,
      text: hasText ? text.trim() : null,
      stickerUrl: hasSticker ? stickerUrl : null,
      musicUrl: hasMusic ? musicUrl : null,
      musicTitle: hasMusic ? musicTitle : null,
      timestamp: DateTime.now(),
    );

    try {
      // Send message through data binding (which now adds it to state)
      await dataBinding.sendMessage(currentUserId, chatRoomId, message);
      resetInactivityTimer(context);
    } catch (e) {
      if (e.toString().contains("BANNED")) {
        dataBinding.setBanned(true);
      }
      print("❌ Error sending message: $e");
    }
  }

  void updateTyping(bool isTyping) {
    _typingTimer?.cancel();
    if (isTyping) {
      dataBinding.updateTyping(chatRoomId, currentUserId, true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        dataBinding.updateTyping(chatRoomId, currentUserId, false);
      });
    } else {
      dataBinding.updateTyping(chatRoomId, currentUserId, false);
    }
  }



  // Show the chat summary dialog with auto-close functionality
  Future<void> showChatSummary(BuildContext context) async {
    // Check if summary already shown
    if (chatState.hasSummaryShown || chatState.isSummaryBeingShown) return;

    // Set flag to prevent concurrent calls
    dataBinding.setSummaryBeingShown(true);
    
    // Initialize the countdown timer in ChatState
    dataBinding.setSummaryCountdownSeconds(10);
    dataBinding.setSummaryTimerActive(true);
    
    // Timer to update the countdown every second
    _summaryTimer?.cancel();
    _summaryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (chatState.summaryCountdownSeconds > 0) {
        dataBinding.setSummaryCountdownSeconds(chatState.summaryCountdownSeconds - 1);
      } else {
        timer.cancel();
        // Auto-close when countdown reaches zero
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.pop(context); // Close the dialog
          dataBinding.markSummaryShown();
          dataBinding.setSummaryBeingShown(false);
          handleExitWithoutSummary(context); // Exit chat without showing summary again
        }
      }
    });

    await showCustomDialog(
      context: context,
      title: "Your Chat Summary",
      content: Consumer<ChatState>(
        builder: (context, chatState, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Safe messages: ${chatState.safeMessageCount} 👍"),
              const SizedBox(height: 4),
              Text("Warning messages: ${chatState.warningMessageCount} ⚠️"),
              const SizedBox(height: 4),
              Text("Unsafe messages: ${chatState.unsafeMessageCount} 🚫"),
              const SizedBox(height: 8),
              Text(
                "Total messages: ${chatState.messages.where((m) => m.senderId == currentUserId).length}",
              ),
              const SizedBox(height: 16),
              if (chatState.isSummaryTimerActive)
                Text(
                  "Dialog will close in ${chatState.summaryCountdownSeconds} seconds...",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Cancel the timer when user manually closes
            _summaryTimer?.cancel();
            dataBinding.setSummaryTimerActive(false);
            Navigator.pop(context);
            dataBinding.markSummaryShown();
            dataBinding.setSummaryBeingShown(false);
            handleExitWithoutSummary(context); // Exit without showing summary again
          },
          child: const Text("Close"),
        ),
      ],
      barrierDismissible: false,
    );
    
    // If we reach here, the dialog was closed by something other than our timer
    _summaryTimer?.cancel();
    dataBinding.setSummaryTimerActive(false);
  }

  // Handle chat exit with summary option
  Future<void> handleChatExit(BuildContext context, {required bool showSummary}) async {
    if (showSummary && !chatState.hasSummaryShown && !chatState.isSummaryBeingShown) {
      await showChatSummary(context);
      // The summary dialog will handle marking summary shown and exiting
    } else {
      await handleExitWithoutSummary(context);
    }
  }

  // Exit chat without showing summary
  Future<void> handleExitWithoutSummary(BuildContext context) async {
    // Stop music playback when chat ends
    if (chatState.isMusicPlaying) {
      dataBinding.setMusicPlaying(false);
    }
    
    await handleExit();
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  // Confirm chat exit with dialog
  Future<void> confirmEndChat(BuildContext context, Function missionTracker) async {
    final shouldEnd = await showConfirmDialog(
      context,
      "End Chat?",
      "Are you sure you want to leave this chat? This action cannot be undone.",
    );
    
    if (shouldEnd) {
      // Mission tracking is now handled in the data binding layer
      await handleChatExit(context, showSummary: true);
    }
  }

  Future<void> handleExit() async {
    if (!_isChatOpen) return;
    _isChatOpen = false;


    try {
      await dataBinding.saveChatSummary(currentUserId, chatRoomId,_chatStartTime!);
      await dataBinding.handleExit(chatRoomId, currentUserId);
      await matchingHandler.updateUserStatus(currentUserId, 'available');
    } finally {
      // Always dispose resources
      dispose();
    }

    print("✅ Chat exit complete for user: $currentUserId");
  }

  Future<void> reportUser() async {
    if (chatState.otherUserId == null) return;
    await dataBinding.reportUser(currentUserId, chatState.otherUserId!);
    dataBinding.setPartnerLeft(true); // Add this
    await dataBinding.closeChatRoom(chatRoomId);
  }

  void startInactivityTimer(BuildContext context) {
    _startInactivityTimer(context);
  }

  // Reset all timers when there's user activity
  void resetInactivityTimer(BuildContext context) {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Reset the countdown counter
    _countdownSeconds = 10;
    
    // Reset the countdown state to zero (to hide any UI warnings)
    dataBinding.setCountdownSeconds(0);
    
    // Explicitly hide the countdown warning
    dataBinding.setCountdownWarningVisible(false);
    
    // Start the timers again
    _startInactivityTimer(context);
  }

  // Clean up resources when chat is closed
  void dispose() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _countdownTimer?.cancel();
    _typingTimer?.cancel();
    _summaryTimer?.cancel();
    typingStatusSubscription?.cancel();
    chatUpdatesSubscription?.cancel();
    
    // Reset internal state
    _isChatOpen = false;
  }

  // Start or restart the inactivity timer
  void _startInactivityTimer(BuildContext? context) {
    const inactivityDuration = Duration(minutes: inactivityDurationMinutes);
    const warningDuration = Duration(minutes: inactivityDurationMinutes - 1, seconds: 50);
    
    // Cancel any existing timers
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _countdownTimer?.cancel();
    
    // Main inactivity timer - will close the chat after 10 minutes
    _inactivityTimer = Timer(inactivityDuration, () {
      if (chatState.isChatOpen) {
        dataBinding.setInactive(true);
        // Close the chat room to notify the other user
        dataBinding.closeChatRoom(chatRoomId);
      }
    });
    
    // Warning timer - will show a countdown 10 seconds before timeout
    _warningTimer = Timer(warningDuration, () {
      if (chatState.isChatOpen && context != null) {
        // Reset the countdown
        _countdownSeconds = 10;
        // Start the countdown timer
        _startCountdownTimer(context);
      }
    });
  }
  
  void _startCountdownTimer(BuildContext context) {
    _countdownTimer?.cancel();
    
    // Make the warning visible
    dataBinding.setCountdownWarningVisible(true);
    
    // Create countdown timer that ticks every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      
      // Send the countdown update to state
      dataBinding.setCountdownSeconds(_countdownSeconds);
      
      // When countdown reaches zero, cancel the timer
      if (_countdownSeconds <= 0) {
        _countdownTimer?.cancel();
      }
      
    });
  }

  Future<void> sendTripJournalMessage(
    BuildContext context,
    List<Map<String, dynamic>> tripJournals,
  ) async {
    print("SENDING trip journal message: $tripJournals");
    if (tripJournals.isEmpty) return;

    final message = MessageModel(
      senderId: currentUserId,
      tripJournals: tripJournals,
      timestamp: DateTime.now(),
      moderationStatus: 'SAFE', // Trip journals are considered safe by default
    );
    try {
      print("🧳 Adding trip journal message to local state");

      print("🧳 Sending trip journal message via WebSocket/Firestore");
      await dataBinding.sendMessage(currentUserId, chatRoomId, message);

      resetInactivityTimer(context);
      print("✅ Trip journal message sent successfully");
    } catch (e) {
      print(
        "❌ Error sending trip journal message: $e",
      ); 
    }
  }

  Future<void> fetchUserTripJournals(String userId) async {
    dataBinding.setIsLoadingTripJournals(true);
    final journals = await dataBinding.fetchUserTripJournals(userId);
    dataBinding.setUserTripJournals(journals);
    dataBinding.setIsLoadingTripJournals(false);
  }

  void updateDrawerVisibility(bool isVisible) {
    dataBinding.setDrawerVisible(isVisible);
  }

  void updateCountdownWarningVisibility(bool isVisible) {
    dataBinding.setCountdownWarningVisible(isVisible);
  }

  void updateStickerVisibility(bool isVisible) {
    dataBinding.setShowStickers(isVisible);
  }

  void clearErrorMessage() {
    dataBinding.setErrorMessage(null);
  }
}
