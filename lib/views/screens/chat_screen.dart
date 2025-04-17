import 'package:blindmate/viewmodels/dataBinding/matching_data_binding.dart';
import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:blindmate/viewmodels/state/matching_state.dart';
import 'package:blindmate/views/UIComponents/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/chat_state.dart';
import '../../viewmodels/eventHandlers/chat_event_handler.dart';
import '../../viewmodels/dataBinding/chat_data_binding.dart';
import '../../views/UIComponents/bottom_drawer.dart';
import '../../views/UIComponents/typing_bubble.dart';
import '../../views/UIComponents/chat_bubble.dart';
import 'mini_game_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();

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

    _chatState.addListener(() {
      if (!mounted || _chatState.hasSummaryShown) return;

      if (_chatState.isBanned) {
        _showBanDialog();
      } else if (_chatState.reportedUser) {
        _showChatSummary().then((_) {
          _chatState.markSummaryShown();
          _chatHandler.handleExit().then((_) {
            Navigator.popUntil(context, (route) => route.isFirst);
          });
        });
      } else if (_chatState.partnerLeft) {
        if (!_chatState.isBanned) {
          _showChatSummary().then((_) {
            _chatState.markSummaryShown();
            _chatHandler.handleExit().then((_) {
              Navigator.popUntil(context, (route) => route.isFirst);
            });
          });
        }
      } else if (_chatState.isInactive) {
        _showInactivityDialog();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatHandler.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.detached) &&
        _chatState.isChatOpen &&
        !_chatState.hasSummaryShown) {
      _chatHandler.handleExit();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User reported. You will not match again."),
          ),
        );
      }
      await _showChatSummary();
      _chatState.markSummaryShown();
      await _chatHandler.handleExit();
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Future<void> _showBanDialog() async {
    if (_chatState.hasSummaryShown) return;

    showErrorDialog(
      context,
      "You have been removed from this chat due to multiple inappropriate messages. "
      "Please be mindful of our community guidelines.",
      onOk: () async {
        await _showChatSummary();
        _chatState.markSummaryShown();
        await _chatHandler.handleExit();
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
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
      await _showChatSummary();
      _chatState.markSummaryShown();
      await _chatHandler.handleExit();
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showChatSummary() async {
    if (_chatState.hasSummaryShown) return;

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

  Future<void> _showInactivityDialog() async {
    if (_chatState.hasSummaryShown) return;

    await showCustomDialog(
      context: context,
      title: "Chat Ended Due to Inactivity",
      content: const Text(
        "No messages were sent for 10 minutes. This chat will now close.",
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _showChatSummary();
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: const Text("OK"),
        ),
      ],
      barrierDismissible: false,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatState>(
      builder: (context, chatState, child) {
        if (chatState.errorMessage != null) {
          // Delay to ensure previous SnackBar is dismissed
          Future.microtask(() {
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(chatState.errorMessage!),
                backgroundColor:
                    chatState.errorMessage!.contains('Warning')
                        ? Colors.orange[400]
                        : Colors.red[400],
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(4),
                duration: const Duration(seconds: 2),
              ),
            );
            // Clear the error message after showing
            chatState.setErrorMessage(null);
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
              title: const Text("Chat"),
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
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              _isDrawerVisible
                                  ? MediaQuery.of(context).size.height *
                                      (_showStickers
                                          ? 0.35
                                          : 0.21) // Adjust padding based on drawer height
                                  : 0,
                        ),
                        child: ListView.builder(
                          reverse: true,
                          itemCount:
                              chatState.messages.length +
                              (chatState.isOtherUserTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (chatState.isOtherUserTyping && index == 0) {
                              return _buildTypingIndicatorBubble();
                            }

                            final messageIndex =
                                chatState.isOtherUserTyping ? index - 1 : index;
                            final message = chatState.messages[messageIndex];
                            final isMe =
                                message.senderId == widget.currentUserId;

                            return _buildChatBubble(message, isMe);
                          },
                        ),
                      ),
                    ),
                    _buildMessageInput(),
                  ],
                ),

                // Bottom drawer overlay
                if (_isDrawerVisible)
                  Positioned(
                    bottom: 0, // Align the drawer to the bottom of the screen
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMessageInput(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height:
                              MediaQuery.of(context).size.height *
                              (_showStickers ? 0.35 : 0.21),
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
                          child: BottomDrawer(
                            onEmojiSelected: (emoji) {
                              _chatHandler.sendMessage(context, text: emoji);
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
                              // Add your mini-game logic here
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MiniGameScreen(
                                        chatRoomId: widget.chatRoomId,
                                        currentUserId: widget.currentUserId,
                                        opponentId:
                                            _chatState.otherUserId ??
                                            '', // fallback if null
                                        isDrawer: true,
                                      ),
                                ),
                              );
                            },
                            onShareMusic: () {
                              // Add your music sharing logic here
                            },
                            onTripJournal: () {
                              // Add your trip journal logic here
                            },
                            onStickerSearch: (query) {
                              _chatHandler.searchStickers(query);
                            },
                            stickerList: _chatState.stickerList,
                            showStickers: _showStickers, // Pass the state
                            toggleStickers: (bool value) {
                              setState(() {
                                _showStickers = value; // Update the state
                              });
                            },
                          ),
                        ),
                      ],
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
    return ChatBubble(isMe: false, child: const TypingBubble());
  }

  Widget _buildChatBubble(message, bool isMe) {
    return ChatBubble(
      isMe: isMe,
      text: message.text,
      stickerUrl: message.stickerUrl,
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _isDrawerVisible =
                    !_isDrawerVisible; // Toggle drawer visibility
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (text) {
                if (text.isNotEmpty) {
                  _chatHandler.updateTyping(true);
                } else {
                  _chatHandler.updateTyping(false);
                }
              },
              onSubmitted: (_) => _chatHandler.resetInactivityTimer(),
              decoration: const InputDecoration(hintText: "Type a message..."),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _chatHandler.sendMessage(context, text: _messageController.text);
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }
}
