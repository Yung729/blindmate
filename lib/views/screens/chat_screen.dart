import 'dart:async';
import 'package:blindmate/services/reward_service.dart';
import 'package:blindmate/viewmodels/dataBinding/matching_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/do_mission_event_handler.dart';
import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:blindmate/viewmodels/state/matching_state.dart';
import 'package:blindmate/views/UIComponents/custom_dialog.dart';
import 'package:blindmate/views/UIComponents/custom_snackbar.dart';
import 'package:blindmate/views/UIComponents/music_search_dialog.dart';
import 'package:blindmate/views/screens/mini_game2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/chat_state.dart';
import '../../viewmodels/eventHandlers/chat_event_handler.dart';
import '../../viewmodels/dataBinding/chat_data_binding.dart';
import '../../views/UIComponents/bottom_drawer.dart';
import '../../views/UIComponents/chat_list_view.dart';
import '../../views/UIComponents/chat_input.dart';
import 'mini_game_screen.dart';
import '../../viewmodels/state/auth_state.dart';
import '../../services/game_invitation_service.dart';
import '../UIComponents/trip_journal_create_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // ViewModel components
  late ChatState _chatState;
  late ChatDataBinding _chatDataBinding;
  late ChatEventHandler _chatEventHandler;
  late MatchingEventHandler _matchingEventHandler;
  
  // UI State
  bool _isDrawerVisible = false;
  bool _showStickers = false;
  bool _isCountdownWarningVisible = false;
  bool _isSummaryBeingShown = false;
  
  // Services
  final RewardService _rewardService = RewardService();
  final GameInvitationService _gameInvitationService = GameInvitationService();
  final MissionEventHandler _missionEventHandler = MissionEventHandler();
  
  // Local tracking
  int _localFlowerCount = 0;
  DateTime? _chatStartTime;

  // Subscriptions
  StreamSubscription? _flowerEventSubscription;
  StreamSubscription? _gameInvitationSubscription;
  StreamSubscription? _gameInvitationResponseSubscription;
  StreamSubscription? _gameInvitationCancellationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeViewModels();
    _setupEventListeners();
    _chatStartTime = DateTime.now();
    
    WidgetsBinding.instance.addObserver(this);
    
    // Add post-frame callback to ensure UI is built before checking state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFlowerCount();
      _handleErrorMessages();
    });
  }

  void _initializeViewModels() {
    // Initialize state
    _chatState = context.read<ChatState>();
    
    // Initialize data bindings
    _chatDataBinding = ChatDataBinding(chatState: _chatState);
    
    // Initialize matchingHandler, needed by chatEventHandler
    final matchingState = context.read<MatchingState>();
    final matchingDataBinding = MatchingDataBinding(matchingState: matchingState);
    _matchingEventHandler = MatchingEventHandler(
      matchingState: matchingState,
      dataBinding: matchingDataBinding,
    );

    // Initialize event handler
    _chatEventHandler = ChatEventHandler(
      chatState: _chatState,
      dataBinding: _chatDataBinding,
      matchingHandler: _matchingEventHandler,
      chatRoomId: widget.chatRoomId,
      currentUserId: widget.currentUserId,
    );

    // Initialize chat
    _chatEventHandler.init();
    _chatEventHandler.startInactivityTimer(context);
    
    // Update local state
    _localFlowerCount = context.read<AuthState>().currentUser?.flower ?? 0;
  }

  void _setupEventListeners() {
    // Listen for chat state changes
    _chatState.addListener(_handleChatStateChanges);

    // Listen to flower events
    _flowerEventSubscription = _rewardService
        .listenToFlowerEvents(widget.chatRoomId)
        .listen(_handleFlowerEvent);

    // Listen for game invitations
    _gameInvitationSubscription = _gameInvitationService
        .listenForInvitations(widget.currentUserId)
        .listen(_handleGameInvitations);

    // Listen for invitation responses
    _gameInvitationResponseSubscription = _gameInvitationService
        .listenForInvitationResponse(widget.currentUserId)
        .listen(_handleGameInvitationResponses);

    // Listen for invitation cancellations
    _gameInvitationCancellationSubscription = _gameInvitationService
        .listenForInvitationCancellation(widget.currentUserId)
        .listen(_handleGameInvitationCancellations);
  }

  void _handleChatStateChanges() {
    if (!mounted || _chatState.hasSummaryShown || _isSummaryBeingShown) {
      return;
    }

    if (_chatState.isBanned) {
      _showBanDialog();
    } else if (_chatState.reportedUser) {
      _handleChatExit(showSummary: true);
    } else if (_chatState.partnerLeft) {
      if (!_chatState.isBanned) {
        _handleChatExit(showSummary: true);
      }
    } else if (_chatState.isInactive) {
      // Auto close without showing dialog
      _handleChatExit(showSummary: true);
    } else if (_chatState.countdownSeconds > 0) {
      // Show the countdown warning
      _showCountdownWarning();
    }
  }

  void _handleFlowerEvent(dynamic snapshot) {
    if (snapshot.docs.isNotEmpty) {
      final event = snapshot.docs.first.data() as Map<String, dynamic>;
      if (event['senderId'] != widget.currentUserId) {
        // Use microtask for better performance
        Future.microtask(() {
          // Show flower animation for the other user
          _chatState.setShowFlowerAnimation(true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _chatState.setShowFlowerAnimation(false);
            }
          });
        });
      }
    }
  }

  void _handleGameInvitations(dynamic snapshot) {
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _showGameInvitationDialog(doc.id, data);
    }
  }

  void _handleGameInvitationResponses(dynamic snapshot) {
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'accepted') {
        Navigator.pop(context); // Close any open dialogs
        _navigateToGame(data['gameType'], data['chatRoomId']);
        _gameInvitationService.deleteInvitation(doc.id);
      } else if (data['status'] == 'declined') {
        Navigator.pop(context); // Close any open dialogs
        CustomSnackBar.show(
          context: context,
          message: "Your partner declined the game invitation",
          status: "WARNING",
        );
        _gameInvitationService.deleteInvitation(doc.id);
      }
    }
  }

  void _handleGameInvitationCancellations(dynamic snapshot) {
    for (var doc in snapshot.docs) {
      // Close any open invitation dialogs
      Navigator.pop(context);
      CustomSnackBar.show(
        context: context,
        message: "Game invitation was cancelled",
        status: "WARNING",
      );
      _gameInvitationService.deleteInvitation(doc.id);
    }
  }

  @override
  void dispose() {
    // Clean up resources
    WidgetsBinding.instance.removeObserver(this);
    _chatState.removeListener(_handleChatStateChanges);
    _chatEventHandler.dispose();
    _flowerEventSubscription?.cancel();
    _gameInvitationSubscription?.cancel();
    _gameInvitationResponseSubscription?.cancel();
    _gameInvitationCancellationSubscription?.cancel();

    // Set music as stopped in the ChatState and close any active player
    if (_chatState.isMusicPlaying) {
      _chatState.setMusicPlaying(false);
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.detached) &&
        _chatState.isChatOpen &&
        !_chatState.hasSummaryShown) {
      // Stop music playback when app goes to background
      if (_chatState.isMusicPlaying) {
        _chatState.setMusicPlaying(false);
      }
      _chatEventHandler.handleExit();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0 && _isDrawerVisible && !_showStickers) {
      // Keyboard is visible and drawer is open, but not in sticker mode
      setState(() {
        _isDrawerVisible = false;
      });
    }
  }

  // UI Actions
  
  Future<void> _showReportDialog() async {
    final shouldReport = await showConfirmDialog(
      context,
      "Report User",
      "Are you sure you want to report this user? You will not be matched with them again.",
    );
    if (shouldReport) {
      await _chatEventHandler.reportUser();
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: "User reported. You will not match again.",
          status: "SUCCESS",
        );
      }
      await _handleChatExit(showSummary: true);
    }
  }

  Future<void> _showBanDialog() async {
    if (_chatState.hasSummaryShown || _isSummaryBeingShown) return;

    showErrorDialog(
      context,
      "You have been removed from this chat due to multiple inappropriate messages. "
      "Please be mindful of our community guidelines.",
      onOk: () async {
        Navigator.pop(context); // Close the dialog
        await _handleChatExit(showSummary: true);
      },
    );
  }

  Future<void> _confirmEndChat() async {
    final shouldEnd = await showConfirmDialog(
      context,
      "End Chat?",
      "Are you sure you want to leave this chat? This action cannot be undone.",
    );
    if (shouldEnd) {
      final durationInSeconds =
          DateTime.now().difference(_chatStartTime!).inSeconds;

      // Track chat time-based mission progress
      await _missionEventHandler.handleTrackMissionProgress(
        category: 'chat',
        type: 'time',
        actionTime: durationInSeconds,
      );
      
      await _handleChatExit(showSummary: true);
    }
  }

  Future<void> _showChatSummary() async {
    // Check both the state flag and local flag to prevent multiple dialogs
    if (_chatState.hasSummaryShown || _isSummaryBeingShown) return;

    // Set local flag to prevent concurrent calls
    _isSummaryBeingShown = true;

    await showCustomDialog(
      context: context,
      title: "Your Chat Summary",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Safe messages: ${_chatState.safeMessageCount} 👍"),
          const SizedBox(height: 4),
          Text("Warning messages: ${_chatState.warningMessageCount} ⚠️"),
          const SizedBox(height: 4),
          Text("Unsafe messages: ${_chatState.unsafeMessageCount} 🚫"),
          const SizedBox(height: 8),
          Text(
            "Total messages: ${_chatState.messages.where((m) => m.senderId == widget.currentUserId).length}",
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Close"),
        ),
      ],
      barrierDismissible: false,
    );
  }

  Future<void> _sendFlower() async {
    final updatedCount = await _rewardService.sendFlower(
      widget.currentUserId,
      widget.chatRoomId,
      context,
    );

    if (updatedCount >= 0) {
      setState(() {
        _localFlowerCount = updatedCount;
      });
      _chatState.setShowFlowerAnimation(true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _chatState.setShowFlowerAnimation(false);
        }
      });
    } else if (updatedCount == -1) {
      CustomSnackBar.show(
        context: context,
        message: "Please wait a moment before sending another flower.",
        status: "WARNING",
        duration: const Duration(seconds: 1),
      );
    } else {
      CustomSnackBar.show(
        context: context,
        message: "You don't have any flowers left!",
        status: "WARNING",
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFlowerCount();
    _handleErrorMessages();
  }

  void _updateFlowerCount() {
    final authState = Provider.of<AuthState>(context, listen: false);
    if (authState.currentUser?.flower != _localFlowerCount) {
      setState(() {
        _localFlowerCount = authState.currentUser?.flower ?? 0;
      });
    }
  }

  void _handleErrorMessages() {
    final chatState = Provider.of<ChatState>(context, listen: false);
    if (chatState.errorMessage != null) {
      Future.microtask(() {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        CustomSnackBar.show(
          context: context,
          message: chatState.errorMessage!,
          status:
              chatState.errorMessage!.contains('Warning') ? 'WARNING' : 'ERROR',
          duration: const Duration(seconds: 2),
        );
        // Clear the error message after showing
        chatState.setErrorMessage(null);
      });
    }
  }

  double _calculateDrawerHeight(BuildContext context, bool showStickers) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Base heights for different states
    double baseHeight =
        screenHeight * 0.38; // 40% of screen height for stickers
    double minHeight = screenHeight * 0.13; // 25% for normal drawer

    // Adjust for keyboard and bottom padding
    if (isKeyboardVisible) {
      baseHeight = screenHeight * 0.38;
      minHeight = screenHeight * 0.35;
    }

    // Add bottom padding for safe area
    final adjustedHeight = showStickers ? baseHeight : minHeight;
    return adjustedHeight + bottomPadding;
  }

  // Message handling
  
  void _handleSendMessage(String text) {
    _chatEventHandler.sendMessage(
      context,
      text: text,
    );
    _chatEventHandler.resetInactivityTimer(context);
    setState(() {
      _isCountdownWarningVisible = false;
    });
  }
  
  // Trip journals
  
  Future<void> _fetchUserTripJournals() async {
    _chatState.isLoadingTripJournals = true;
    final journals = await _chatDataBinding.fetchUserTripJournals(
      widget.currentUserId,
    );
    if (mounted) {
      setState(() {
        _chatState.userTripJournals = journals;
        _chatState.isLoadingTripJournals = false;
      });
    }
  }
  
  // Game handling
  
  void _showGameInvitationDialog(
    String invitationId,
    Map<String, dynamic> data,
  ) {
    final gameType = data['gameType'] as String;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Invitation"),
        content: Text("Your partner wants to play $gameType with you!"),
        actions: [
          TextButton(
            onPressed: () async {
              await _gameInvitationService.respondToInvitation(
                invitationId,
                false,
              );
              Navigator.pop(context);
            },
            child: const Text("Decline"),
          ),
          TextButton(
            onPressed: () async {
              await _gameInvitationService.respondToInvitation(
                invitationId,
                true,
              );
              Navigator.pop(context);
              _navigateToGame(gameType, data['chatRoomId']);
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  void _navigateToGame(String gameType, String chatRoomId) {
    if (gameType == 'Draw & Guess') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MiniGameScreen(
            chatRoomId: chatRoomId,
            currentUserId: widget.currentUserId,
            opponentId: _chatState.otherUserId ?? '',
            isDrawer: true,
          ),
        ),
      );
    } else if (gameType == 'Tic Tac Toe') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MiniGame2Screen(
            chatRoomId: chatRoomId,
            currentUserId: widget.currentUserId,
            opponentId: _chatState.otherUserId ?? '',
            isPlayerX: true,
          ),
        ),
      );
    }
  }

  void _showGameSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Game"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.draw, color: Colors.blue),
              title: const Text("Draw & Guess"),
              subtitle: const Text("Draw and let your partner guess"),
              onTap: () {
                Navigator.pop(context);
                _handleGameSelection("Draw & Guess");
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.grid_on, color: Colors.green),
              title: const Text("Tic Tac Toe"),
              subtitle: const Text("Classic X and O game"),
              onTap: () {
                Navigator.pop(context);
                _handleGameSelection("Tic Tac Toe");
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _handleGameSelection(String gameType) {
    if (_chatState.otherUserId == null) return;

    String? currentInvitationId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Sending Invitation"),
        content: const Text(
          "Waiting for your partner to accept the game invitation...",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (currentInvitationId != null) {
                await _gameInvitationService.cancelInvitation(
                  currentInvitationId!,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    _gameInvitationService
        .sendInvitation(
          chatRoomId: widget.chatRoomId,
          senderId: widget.currentUserId,
          receiverId: _chatState.otherUserId!,
          gameType: gameType,
        )
        .then((invitationId) {
          currentInvitationId = invitationId;
        });
  }

  Future<void> _handleChatExit({required bool showSummary}) async {
    if (showSummary) {
      await _showChatSummary();
      _chatState.markSummaryShown();
      _isSummaryBeingShown = false;
    }
    
    // Stop music playback when chat ends
    if (_chatState.isMusicPlaying) {
      _chatState.setMusicPlaying(false);
    }
    
    await _chatEventHandler.handleExit();
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _showCountdownWarning() {
    // Only show if not already shown
    if (!_isCountdownWarningVisible) {
      _isCountdownWarningVisible = true;
      
      // Clear any existing snackbars
      ScaffoldMessenger.of(context).clearSnackBars();
      
      // Use the CustomSnackBar component with action button
      CustomSnackBar.show(
        context: context,
        message: '⚠️ Chat inactive! Will close in ${_chatState.countdownSeconds} seconds.',
        status: 'WARNING',
        duration: const Duration(seconds: 10),
        actionLabel: 'Keep Chatting',
        onActionPressed: () {
          // Reset the inactivity timer
          _chatEventHandler.resetInactivityTimer(context);
          _isCountdownWarningVisible = false;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatState, AuthState>(
      builder: (context, chatState, authState, child) {
        // Schedule state updates with microtask for better performance
        if (authState.currentUser?.flower != _localFlowerCount ||
            chatState.errorMessage != null) {
          Future.microtask(() {
            if (!mounted) return;
            _updateFlowerCount();
            _handleErrorMessages();
          });
        }

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (!didPop) {
              await _confirmEndChat();
            }
          },
          child: Scaffold(
            appBar: _buildAppBar(authState),
            body: Stack(
              children: [
                // Main chat UI
                _buildMainChatUI(chatState, authState),

                // Bottom drawer overlay
                if (_isDrawerVisible)
                  _buildBottomDrawer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainChatUI(ChatState chatState, AuthState authState) {
    return Column(
      children: [
        if (chatState.showFlowerAnimation)
          Center(
            child: Image.asset(
              'assets/flower.gif',
              width: 120,
              height: 120,
            ),
          ),

        ChatListView(
          chatState: chatState,
          currentUserId: widget.currentUserId,
          currentUserAvatarImg: authState.currentUser?.avatarImg,
          isDrawerVisible: _isDrawerVisible,
          calculateDrawerHeight: _calculateDrawerHeight,
          showStickers: _showStickers,
        ),
        
        ChatInput(
          onSendMessage: _handleSendMessage,
          onTypingChanged: _chatEventHandler.updateTyping,
          onPlusButtonPressed: () {
            setState(() {
              _isDrawerVisible = !_isDrawerVisible;
              _isCountdownWarningVisible = false;
            });
          },
          onResetInactivityTimer: () {
            _chatEventHandler.resetInactivityTimer(context);
            setState(() {
              _isCountdownWarningVisible = false;
            });
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(AuthState authState) {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage:
                (authState.currentUser?.avatarImg != null &&
                        authState.currentUser!.avatarImg.isNotEmpty)
                    ? NetworkImage(authState.currentUser!.avatarImg)
                    : const AssetImage('assets/default_pic.jpg')
                        as ImageProvider,
          ),
          const SizedBox(width: 8),
          const Text("Chat"),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _confirmEndChat(),
      ),
      actions: [
        if (_chatState.otherUserId != null)
          IconButton(
            icon: const Icon(Icons.flag, color: Colors.red),
            onPressed: () => _showReportDialog(),
          ),
      ],
    );
  }

  Widget _buildBottomDrawer() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatInput(
              onSendMessage: _handleSendMessage,
              onTypingChanged: _chatEventHandler.updateTyping,
              onPlusButtonPressed: () {
                setState(() {
                  _isDrawerVisible = !_isDrawerVisible;
                  _isCountdownWarningVisible = false;
                });
              },
              onResetInactivityTimer: () {
                _chatEventHandler.resetInactivityTimer(context);
                setState(() {
                  _isCountdownWarningVisible = false;
                });
              },
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _calculateDrawerHeight(
                context,
                _showStickers,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: _calculateDrawerHeight(
                    context,
                    _showStickers,
                  ),
                  child: BottomDrawer(
                    onFlowerSelected: (_) async {
                      await _sendFlower();
                      setState(() {
                        _isDrawerVisible = false;
                      });
                    },
                    onStickerSelected: (sticker) {
                      _chatEventHandler.sendMessage(
                        context,
                        stickerUrl: sticker,
                      );
                      setState(() {
                        _isDrawerVisible = false;
                        _showStickers = false;
                      });
                    },
                    onPlayMiniGame: () {
                      _showGameSelectionDialog();
                    },
                    onShareMusic: () {
                      MusicSearchDialog.show(
                        context,
                        onMusicSelected: (url, title) {
                          _chatEventHandler.sendMessage(
                            context,
                            musicUrl: url,
                            musicTitle: title,
                          );
                          setState(() {
                            _isDrawerVisible = false;
                          });
                        },
                      );
                    },
                    onTripJournal: () async {
                      await _fetchUserTripJournals();
                      TripJournalDialog.show(
                        context,
                        initialEntries: [],
                        onJournalsAdded: (entries) async {
                          if (entries.isNotEmpty) {
                            await _chatEventHandler
                                .sendTripJournalMessage(
                                  context,
                                  entries,
                                );
                            setState(() {
                              _isDrawerVisible = false;
                            });
                          }
                        },
                        pastJournals: _chatState.userTripJournals,
                        actionButtonText: 'Send Journal',
                      );
                    },
                    onStickerSearch: (query) {
                      _chatEventHandler.searchStickers(query);
                    },
                    stickerList: _chatState.stickerList,
                    showStickers: _showStickers,
                    toggleStickers: (bool value) {
                      setState(() {
                        _showStickers = value;
                      });
                    },
                    flowerCount: _localFlowerCount,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
