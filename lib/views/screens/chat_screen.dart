import 'dart:async';
import 'package:blindmate/viewmodels/dataBinding/matching_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/mission_event_handler.dart';
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
import 'package:blindmate/viewmodels/state/do_mission_state.dart';

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

  // Local tracking
  int _localFlowerCount = 0;

  // Services
  final GameInvitationService _gameInvitationService = GameInvitationService();
  late MissionEventHandler _missionEventHandler;

  // Subscriptions
  StreamSubscription? _gameInvitationSubscription;
  StreamSubscription? _gameInvitationResponseSubscription;
  StreamSubscription? _gameInvitationCancellationSubscription;

  // Track keyboard visibility
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeViewModels();
    _setupEventListeners();

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
    final missionState = context.read<MissionState>();

    // Initialize data bindings
    _chatDataBinding = ChatDataBinding(
      chatState: _chatState,
      missionState: missionState,
    );

    // Initialize matchingHandler, needed by chatEventHandler
    final matchingState = context.read<MatchingState>();
    final matchingDataBinding = MatchingDataBinding(
      matchingState: matchingState,
    );
    _matchingEventHandler = MatchingEventHandler(
      matchingState: matchingState,
      dataBinding: matchingDataBinding,
    );

    // Initialize mission event handler with mission state
    _missionEventHandler = MissionEventHandler(missionState: missionState);

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
    if (!mounted ||
        _chatState.hasSummaryShown ||
        _chatState.isSummaryBeingShown) {
      return;
    }

    if (_chatState.isBanned) {
      _showBanDialog();
    } else if (_chatState.reportedUser) {
      _chatEventHandler.handleChatExit(context, showSummary: true);
    } else if (_chatState.partnerLeft) {
      if (!_chatState.isBanned) {
        _chatEventHandler.handleChatExit(context, showSummary: true);
      }
    } else if (_chatState.isInactive) {
      // Auto close without showing dialog
      _chatEventHandler.handleChatExit(context, showSummary: true);
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
    _gameInvitationSubscription?.cancel();
    _gameInvitationResponseSubscription?.cancel();
    _gameInvitationCancellationSubscription?.cancel();

    // Stop music playback when screen is closed
    if (_chatState.isMusicPlaying) {
      _chatDataBinding.setMusicPlaying(false);
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
        _chatDataBinding.setMusicPlaying(false);
      }
      _chatEventHandler.handleExit();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // If keyboard newly appears (was not visible before and is visible now)
    // and drawer is visible, close the drawer
    if (bottomInset > 0 && !_isKeyboardVisible && _chatState.isDrawerVisible) {
      // Only close drawer if we're not showing stickers (sticker search needs keyboard)
      if (!_chatState.showStickers) {
        _chatEventHandler.updateDrawerVisibility(false);
      }
    }

    // Update keyboard visibility tracking
    _isKeyboardVisible = bottomInset > 0;
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
      await _chatEventHandler.handleChatExit(context, showSummary: true);
    }
  }

  Future<void> _showBanDialog() async {
    if (_chatState.hasSummaryShown || _chatState.isSummaryBeingShown) return;

    showErrorDialog(
      context,
      "You have been removed from this chat due to multiple inappropriate messages. "
      "Please be mindful of our community guidelines.",
      onOk: () async {
        Navigator.pop(context); // Close the dialog
        await _chatEventHandler.handleChatExit(context, showSummary: true);
      },
    );
  }

  Future<void> _confirmEndChat() async {
    await _chatEventHandler.confirmEndChat(
      context,
      _missionEventHandler.trackMissionProgress,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFlowerCount();
    _handleErrorMessages();
  }

  Future<void> _sendFlower() async {
    final updatedCount = await _chatEventHandler.sendFlower(context);

    if (updatedCount >= 0) {
      setState(() {
        _localFlowerCount = updatedCount;
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
        _chatEventHandler.clearErrorMessage();
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
    _chatEventHandler.sendMessage(context, text: text);
    _chatEventHandler.resetInactivityTimer(context);
  }

  // Trip journals

  Future<void> _fetchUserTripJournals() async {
    await _chatEventHandler.fetchUserTripJournals(widget.currentUserId);
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
      builder:
          (context) => AlertDialog(
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
          builder:
              (context) => MiniGameScreen(
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
          builder:
              (context) => MiniGame2Screen(
                chatRoomId: chatRoomId,
                currentUserId: widget.currentUserId,
                opponentId: _chatState.otherUserId ?? '',
                isPlayerX: true, // First player is always X
              ),
        ),
      );
    }
  }

  void _showGameSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
      builder:
          (context) => AlertDialog(
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
                if (chatState.isDrawerVisible) _buildBottomDrawer(),
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
            child: Image.asset('assets/flower.gif', width: 120, height: 120),
          ),

        // Add countdown warning directly based on state
        if (chatState.countdownSeconds > 0 &&
            chatState.isCountdownWarningVisible)
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat inactive! Will close in ${chatState.countdownSeconds} seconds.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ChatListView(
          chatState: chatState,
          currentUserId: widget.currentUserId,
          currentUserAvatarImg: authState.currentUser?.avatarImg,
          isDrawerVisible: chatState.isDrawerVisible,
          calculateDrawerHeight: _calculateDrawerHeight,
          showStickers: chatState.showStickers,
        ),

        ChatInput(
          onSendMessage: _handleSendMessage,
          onTypingChanged: (isTyping) {
            // Only update typing state without affecting drawer
            _chatEventHandler.updateTyping(isTyping);
          },
          onPlusButtonPressed: () {
            _chatEventHandler.updateDrawerVisibility(
              !chatState.isDrawerVisible,
            );
            _chatEventHandler.updateCountdownWarningVisibility(false);
          },
          onResetInactivityTimer: () {
            _chatEventHandler.resetInactivityTimer(context);
            _chatEventHandler.updateCountdownWarningVisibility(false);
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
            // We will show the same ChatInput component that's already in the main UI
            // This creates the illusion of the drawer opening below the input
            ChatInput(
              onSendMessage: _handleSendMessage,
              onTypingChanged: (isTyping) {
                _chatEventHandler.updateTyping(isTyping);
              },
              onPlusButtonPressed: () {
                // Close drawer when plus is pressed from inside drawer
                _chatEventHandler.updateDrawerVisibility(false);
                _chatEventHandler.updateCountdownWarningVisibility(false);
              },
              onResetInactivityTimer: () {
                _chatEventHandler.resetInactivityTimer(context);
                _chatEventHandler.updateCountdownWarningVisibility(false);
              },
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _calculateDrawerHeight(context, _chatState.showStickers),
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
                    _chatState.showStickers,
                  ),
                  child: BottomDrawer(
                    onFlowerSelected: (_) async {
                      await _sendFlower();
                      _chatEventHandler.updateDrawerVisibility(false);
                    },
                    onStickerSelected: (sticker) {
                      _chatEventHandler.sendMessage(
                        context,
                        stickerUrl: sticker,
                      );
                      _chatEventHandler.updateDrawerVisibility(false);
                      _chatEventHandler.updateStickerVisibility(false);
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
                          _chatEventHandler.updateDrawerVisibility(false);
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
                            await _chatEventHandler.sendTripJournalMessage(
                              context,
                              entries,
                            );
                            _chatEventHandler.updateDrawerVisibility(false);
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
                    showStickers: _chatState.showStickers,
                    toggleStickers: (bool value) {
                      _chatEventHandler.updateStickerVisibility(value);
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
