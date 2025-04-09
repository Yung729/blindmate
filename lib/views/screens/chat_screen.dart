import 'package:blindmate/viewmodels/eventHandlers/matching_event_handler.dart';
import 'package:blindmate/viewmodels/state/matching_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/chat_state.dart';
import '../../viewmodels/eventHandlers/chat_event_handler.dart';
import '../../viewmodels/dataBinding/chat_data_binding.dart';
import '../../views/UIComponents/bottom_drawer.dart';
import '../../views/UIComponents/typing_bubble.dart';

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
    final matchingHandler = MatchingEventHandler(
      matchingState: context.read<MatchingState>(),
    );

    _chatHandler = ChatEventHandler(
      chatState: _chatState,
      dataBinding: chatBinding,
      matchingHandler: matchingHandler, // ✅ Injecting the MatchingService
      chatRoomId: widget.chatRoomId,
      currentUserId: widget.currentUserId,
    );

    _chatHandler.init();

    WidgetsBinding.instance.addObserver(this);
    _chatHandler.startInactivityTimer(context);

    _chatState.addListener(() {
      if (_chatState.partnerLeft) {
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _chatHandler.handleExit();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatState>(
      builder: (context, chatState, child) {
        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) async {
            if (didPop) {
              await _chatHandler.handleExit();
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
                onPressed: () async {
                  await _chatHandler.confirmEndChat(context);
                },
              ),
              actions: [
                if (chatState.otherUserId != null)
                  IconButton(
                    icon: const Icon(Icons.flag, color: Colors.red),
                    onPressed:
                        () async => await _chatHandler.reportUser(context),
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
                                          ? 0.25
                                          : 0.2) // Adjust padding based on drawer height
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
                              (_showStickers ? 0.21 : 0.14),
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
                              _chatHandler.sendMessage(text: emoji);
                              setState(() {
                                _isDrawerVisible = false;
                              });
                            },
                            onStickerSelected: (sticker) {
                              _chatHandler.sendMessage(stickerUrl: sticker);
                              setState(() {
                                _isDrawerVisible = false;
                                _showStickers = false;
                              });
                            },
                            onPlayMiniGame: () {
                              // Add your mini-game logic here
                            },
                            onShareMusic: () {
                              // Add your music sharing logic here
                            },
                            onTripJournal: () {
                              // Add your trip journal logic here
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.start, // Partner typing, align left
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(
              'assets/default_pic.jpg',
            ), // Replace with other user's avatar if you have it
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300], // Match other user's bubble color
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const TypingBubble(), // Your custom animated bubble widget
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/default_pic.jpg'),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blueAccent : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child:
                  message.stickerUrl != null
                      ? Image.network(message.stickerUrl!, height: 100)
                      : Text(
                        message.text ?? "",
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/default_pic.jpg'),
            ),
        ],
      ),
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
              _chatHandler.sendMessage(text: _messageController.text);
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }
}
