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
import '../../views/UIComponents/typing_bubble.dart';
import '../../views/UIComponents/chat_bubble.dart';
import 'mini_game_screen.dart';
import '../../viewmodels/state/auth_state.dart';
import '../../services/game_invitation_service.dart';
import '../UIComponents/trip_journal_create_dialog.dart';
import '../UIComponents/trip_journal_card.dart';

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
  late ChatEventHandler _chatHandler;
  late ChatState _chatState;
  late TextEditingController _messageController;
  bool _isDrawerVisible = false;
  bool _showStickers = false;
  bool _isCountdownWarningVisible = false;
  final RewardService _rewardService = RewardService();
  final GameInvitationService _gameInvitationService = GameInvitationService();
  int _localFlowerCount = 0;
  StreamSubscription? _flowerEventSubscription;
  StreamSubscription? _gameInvitationSubscription;
  StreamSubscription? _gameInvitationResponseSubscription;
  StreamSubscription? _gameInvitationCancellationSubscription;
  DateTime? _chatStartTime;
  final _missionEventHandler = MissionEventHandler();

  Future<void> _fetchUserTripJournals() async {
    _chatState.isLoadingTripJournals = true;
    final chatBinding = ChatDataBinding(chatState: _chatState);
    final journals = await chatBinding.fetchUserTripJournals(
      widget.currentUserId,
    );
    setState(() {
      _chatState.userTripJournals = journals;
      _chatState.isLoadingTripJournals = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _localFlowerCount = context.read<AuthState>().currentUser?.flower ?? 0;
    _chatStartTime = DateTime.now();

    _chatState = context.read<ChatState>();
    final chatBinding = ChatDataBinding(chatState: _chatState);

    final matchingState = context.read<MatchingState>();
    final matchingDataBinding = MatchingDataBinding(
      matchingState: matchingState,
    );

    final matchingHandler = MatchingEventHandler(
      matchingState: matchingState,
      dataBinding: matchingDataBinding,
    );

    _chatHandler = ChatEventHandler(
      chatState: _chatState,
      dataBinding: chatBinding,
      matchingHandler: matchingHandler,
      chatRoomId: widget.chatRoomId,
      currentUserId: widget.currentUserId,
    );

    _chatHandler.init();

    WidgetsBinding.instance.addObserver(this);
    _chatHandler.startInactivityTimer(context);

    // Add post-frame callback to ensure UI is built before checking state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFlowerCount();
      _handleErrorMessages();
    });

    _chatState.addListener(() {
      if (!mounted || _chatState.hasSummaryShown || _isSummaryBeingShown)
        return;

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
    });

    // Listen to flower events
    _flowerEventSubscription = _rewardService
        .listenToFlowerEvents(widget.chatRoomId)
        .listen((snapshot) {
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
        });

    // Listen for game invitations
    _gameInvitationSubscription = _gameInvitationService
        .listenForInvitations(widget.currentUserId)
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            _showGameInvitationDialog(doc.id, data);
          }
        });

    // Listen for invitation responses
    _gameInvitationResponseSubscription = _gameInvitationService
        .listenForInvitationResponse(widget.currentUserId)
        .listen((snapshot) {
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
        });

    // Listen for invitation cancellations
    _gameInvitationCancellationSubscription = _gameInvitationService
        .listenForInvitationCancellation(widget.currentUserId)
        .listen((snapshot) {
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
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatHandler.dispose();
    _messageController.dispose();
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
      _chatHandler.handleExit();
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

  Future<void> _showReportDialog() async {
    final shouldReport = await showConfirmDialog(
      context,
      "Report User",
      "Are you sure you want to report this user? You will not be matched with them again.",
    );
    if (shouldReport) {
      await _chatHandler.reportUser();
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

      // ✅ Track chat time-based mission progress
      await _missionEventHandler.handleTrackMissionProgress(
        category: 'chat',
        type: 'time',
        actionTime: durationInSeconds,
      );
      
      await _handleChatExit(showSummary: true);
    }
  }

  // Local flag to prevent multiple summary dialogs
  bool _isSummaryBeingShown = false;

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
      // Changed from > 0 to >= 0 to include when last flower is sent
      setState(() {
        _localFlowerCount = updatedCount;
      });
      // Show animation even when the last flower is sent (when updatedCount becomes 0)
      _chatState.setShowFlowerAnimation(true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _chatState.setShowFlowerAnimation(false);
        }
      });
    } else if (updatedCount == -1) {
      // Show cooldown message
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
    // Check for auth state changes outside of build
    final authState = Provider.of<AuthState>(context, listen: false);
    if (authState.currentUser?.flower != _localFlowerCount) {
      setState(() {
        _localFlowerCount = authState.currentUser?.flower ?? 0;
      });
    }
  }

  void _handleErrorMessages() {
    // Handle error messages outside of build
    final chatState = Provider.of<ChatState>(context, listen: false);
    if (chatState.errorMessage != null) {
      // Use microtask for better performance
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

  @override
  Widget build(BuildContext context) {
    // Listen for changes but don't update state during build
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
            appBar: AppBar(
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
                if (chatState.otherUserId != null)
                  IconButton(
                    icon: const Icon(Icons.flag, color: Colors.red),
                    onPressed: () => _showReportDialog(),
                  ),
              ],
            ),
            body: Stack(
              children: [
                // Main chat UI
                Column(
                  children: [
                    if (chatState.showFlowerAnimation)
                      Center(
                        child: Image.asset(
                          'assets/flower.gif',
                          width: 120,
                          height: 120,
                        ),
                      ),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              _isDrawerVisible
                                  ? _calculateDrawerHeight(
                                    context,
                                    _showStickers,
                                  )
                                  : 0,
                        ),
                        child: ListView.custom(
                          reverse: true,
                          childrenDelegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (chatState.isOtherUserTyping && index == 0) {
                                return _buildTypingIndicatorBubble();
                              }

                              final messageIndex =
                                  chatState.isOtherUserTyping
                                      ? index - 1
                                      : index;
                              final message = chatState.messages[messageIndex];
                              final isMe =
                                  message.senderId == widget.currentUserId;

                              // Create a unique key based on the message ID
                              final uniqueKey = message.messageId;
                              return KeyedSubtree(
                                key: ValueKey('message-$uniqueKey'),
                                child: _buildChatBubble(
                                  message,
                                  isMe,
                                  authState.currentUser?.avatarImg,
                                ),
                              );
                            },
                            // This preserves state across rebuilds
                            findChildIndexCallback: (key) {
                              final ValueKey<String> valueKey =
                                  key as ValueKey<String>;
                              final String keyString = valueKey.value;

                              // Skip for typing indicator
                              if (keyString == 'typing-indicator') return null;

                              // Extract unique message key from the key string
                              final String messageUniqueKey = keyString
                                  .replaceFirst('message-', '');

                              // Find the index of the message with this unique key
                              final int
                              messageIndex = chatState.messages.indexWhere(
                                (m) => m.messageId == messageUniqueKey,
                              );
                              if (messageIndex < 0) return null;

                              // Adjust for typing indicator if present
                              return chatState.isOtherUserTyping
                                  ? messageIndex + 1
                                  : messageIndex;
                            },
                            childCount:
                                chatState.messages.length +
                                (chatState.isOtherUserTyping ? 1 : 0),
                          ),
                        ),
                      ),
                    ),
                    _buildMessageInput(),
                  ],
                ),

                // Bottom drawer overlay
                if (_isDrawerVisible)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMessageInput(),
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
                                    _chatHandler.sendMessage(
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
                                        _chatHandler.sendMessage(
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
                                          await _chatHandler
                                              .sendTripJournalMessage(
                                                context,
                                                entries,
                                              );
                                          setState(() {
                                            _isDrawerVisible = false;
                                          });
                                        }
                                      },
                                      pastJournals: chatState.userTripJournals,
                                      actionButtonText: 'Send Journal',
                                    );
                                  },
                                  onStickerSearch: (query) {
                                    _chatHandler.searchStickers(query);
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicatorBubble() {
    return KeyedSubtree(
      key: const ValueKey('typing-indicator'),
      child: ChatBubble(
        isMe: false,
        child: const TypingBubble(),
        showAvatar: true,
      ),
    );
  }

  Widget _buildChatBubble(message, bool isMe, String? currentUserAvatarImg) {
    // Determine if this message should show avatar based on the next message
    final messageIndex = _chatState.messages.indexOf(message);
    final nextMessage =
        messageIndex < _chatState.messages.length - 1
            ? _chatState.messages[messageIndex + 1]
            : null;

    // Show avatar if it's the last message from this sender
    final showAvatar =
        nextMessage == null || nextMessage.senderId != message.senderId;

    // --- Trip Journal Support ---
    if (message.tripJournals != null && message.tripJournals!.isNotEmpty) {
      // Show trip journal card in chat bubble
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: ChatBubble(
          isMe: isMe,
          avatarUrl:
              isMe ? currentUserAvatarImg : _chatState.otherUserAvatarImg,
          timestamp: message.timestamp,
          showAvatar: showAvatar,
          child: TripJournalBookCard(journals: message.tripJournals!),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: ChatBubble(
        isMe: isMe,
        text: message.text,
        stickerUrl: message.stickerUrl,
        musicUrl: message.musicUrl,
        musicTitle: message.musicTitle,
        avatarUrl: isMe ? currentUserAvatarImg : _chatState.otherUserAvatarImg,
        timestamp: message.timestamp,
        showAvatar: showAvatar,
        moderationStatus: message.moderationStatus,
      ),
    );
  }

  Widget _buildMessageInput() {
    final bool hasText = _messageController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4.0,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue[400],
                  size: 26,
                ),
                onPressed: () {
                  // Dismiss keyboard when opening drawer
                  FocusScope.of(context).unfocus();
                  // Reset inactivity timer on interaction
                  _chatHandler.resetInactivityTimer(context);
                  setState(() {
                    _isDrawerVisible = !_isDrawerVisible;
                    _isCountdownWarningVisible = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 16),
                        onChanged: (text) {
                          setState(
                            () {},
                          ); // Rebuild to update send button color
                          if (text.isNotEmpty) {
                            _chatHandler.updateTyping(true);
                          } else {
                            _chatHandler.updateTyping(false);
                          }
                          // Reset inactivity timer when typing
                          _chatHandler.resetInactivityTimer(context);
                          _isCountdownWarningVisible = false;
                        },
                        onSubmitted: (_) => _chatHandler.resetInactivityTimer(context),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: hasText ? Colors.blue[400] : Colors.grey[300],
                          size: 24,
                        ),
                        onPressed:
                            hasText
                                ? () {
                                  _chatHandler.sendMessage(
                                    context,
                                    text: _messageController.text,
                                  );
                                  _messageController.clear();
                                  // Reset inactivity timer and clear countdown warning
                                  _chatHandler.resetInactivityTimer(context);
                                  setState(() {
                                    _isCountdownWarningVisible = false;
                                  });
                                }
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            title: Text("Game Invitation"),
            content: Text("Your partner wants to play $gameType with you!"),
            actions: [
              TextButton(
                onPressed: () async {
                  await _gameInvitationService.respondToInvitation(
                    invitationId,
                    false,
                  );
                  Navigator.pop(context); // Just close the dialog
                },
                child: Text("Decline"),
              ),
              TextButton(
                onPressed: () async {
                  await _gameInvitationService.respondToInvitation(
                    invitationId,
                    true,
                  );
                  Navigator.pop(context); // Close the dialog
                  _navigateToGame(gameType, data['chatRoomId']);
                },
                child: Text("Accept"),
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
                isPlayerX: true,
              ),
        ),
      );
    }
  }

  void _handleGameSelection(String gameType) {
    if (_chatState.otherUserId == null) return;

    String? currentInvitationId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text("Sending Invitation"),
            content: Text(
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
                child: Text("Cancel"),
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

  void _showGameSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Select Game"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.draw, color: Colors.blue),
                  title: Text("Draw & Guess"),
                  subtitle: Text("Draw and let your partner guess"),
                  onTap: () {
                    Navigator.pop(context);
                    _handleGameSelection("Draw & Guess");
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.grid_on, color: Colors.green),
                  title: Text("Tic Tac Toe"),
                  subtitle: Text("Classic X and O game"),
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
                child: Text("Cancel"),
              ),
            ],
          ),
    );
  }

  // Add a helper method to handle chat exit consistently
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
    
    await _chatHandler.handleExit();
    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  // Add a helper method to show the countdown warning
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
          _chatHandler.resetInactivityTimer(context);
          _isCountdownWarningVisible = false;
        },
      );
    }
  }
}
