import 'dart:async';
import 'package:blindmate/views/UIComponents/typing_bubble.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../services/emoji_service.dart';
import '../../services/giphy_service.dart';
import '../../services/matching_service.dart';
import '../../models/message_model.dart';
import '../UIComponents/bottom_drawer.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final MatchingService _matchingService = MatchingService();
  final EmojiService _emojiService = EmojiService();
  final GiphyService _giphyService = GiphyService();

  List<String> _emojiList = [];
  List<String> _stickerList = [];
  bool partnerLeft = false;
  bool _isChatOpen = true;
  bool isTyping = false;
  bool isOtherUserTyping = false;
  String? otherUserId;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _chatService.connectWebSocket(widget.chatRoomId);
    _loadEmojis();
    _loadStickers("funny");
    WidgetsBinding.instance.addObserver(this);
    _fetchChatPartner();
    _startInactivityTimer();

    // Listen for typing status updates
    _chatService.getTypingStatus(widget.chatRoomId).listen((typingData) {
      if (typingData.containsKey(otherUserId)) {
        setState(() {
          isOtherUserTyping = typingData[otherUserId] == true;
        });
      }
    });

    // Listen for chat closure (partner leaving)
    _chatService.listenForChatUpdates(widget.chatRoomId).listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data['closed'] == true) {
          setState(() => partnerLeft = true);
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.popUntil(context, (route) => route.isFirst);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // Detect app lifecycle changes (Close chat when app is closed)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _handleExit();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel(); // Cancel existing timer
    _inactivityTimer = Timer(const Duration(minutes: 10), () {
      _showInactivityDialog();
    });
  }

  Future<void> _showInactivityDialog() async {
    if (!mounted) return;

    bool? shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chat Ended Due to Inactivity"),
        content: const Text(
          "No messages were sent for 10 minutes. This chat will now close.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleExit();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      _handleExit();
    }
  }

  // Call this when sending a message to reset timer
  void _onMessageSent() {
    _startInactivityTimer();
  }

  // Fetch the other user's ID in the chat
  void _fetchChatPartner() async {
    final chatDoc =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatRoomId)
            .get();

    if (chatDoc.exists) {
      List<String> users = List<String>.from(chatDoc['users']);
      users.remove(widget.currentUserId); // Remove current user ID
      if (users.isNotEmpty) {
        setState(() {
          otherUserId =
              users.first; // Set the remaining user as the chat partner
        });
      }
    }
  }

  // Report user function
  void _reportUser() async {
    if (otherUserId == null) return;

    await _chatService.reportUser(widget.currentUserId, otherUserId!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User reported. You will not match again.")),
    );

    await _handleExit();
  }

  Future<void> _confirmEndChat() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Chat?"),
        content: const Text(
          "Are you sure you want to leave this chat? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: _handleExit,
            child: const Text(
              "End Chat",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Handle closing the chat room
  Future<void> _handleExit() async {
    if (!_isChatOpen) return;
    _isChatOpen = false;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) return; // Chat does not exist

    List<String> users = List<String>.from(chatDoc['users']);
    users.remove(widget.currentUserId);

    _chatService.closeConnection();

    if (users.isEmpty) {
      await _chatService.closeChatRoom(widget.chatRoomId, users);
    } else {
      await chatRef.update({'closed': true});
      await _matchingService.updateUserStatus(widget.currentUserId, 'available');
    }

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _sendMessage({String? text, String? stickerUrl}) {
    if ((text == null || text.trim().isEmpty) &&
        (stickerUrl == null || stickerUrl.isEmpty)) {
      return;
    }

    _chatService.sendMessage(
      widget.currentUserId,
      widget.chatRoomId,
      MessageModel(
        senderId: widget.currentUserId,
        text: text?.trim(),
        stickerUrl: stickerUrl,
        timestamp: DateTime.now(),
      ),
    );

    if (text != null) {
      _messageController.clear();
      _updateTypingStatus(false);
    }
  }

  void _updateTypingStatus(bool typing) {
    if (typing != isTyping) {
      setState(() => isTyping = typing);
      _chatService.updateTypingStatus(
        widget.chatRoomId,
        widget.currentUserId,
        typing,
      );
    }
  }

  void _loadEmojis() async {
    try {
      List<String> emojis = await _emojiService.fetchEmojis();
      setState(() {
        _emojiList = emojis.take(40).toList();
      });
    } catch (e) {
      print("❌ Failed to load emojis: $e");
    }
  }

  void _loadStickers(String query) async {
    try {
      List<String> stickers = await _giphyService.fetchStickers(query);
      setState(() {
        _stickerList = stickers;
      });
    } catch (e) {
      print("❌ Failed to load STICKER: $e");
    }
  }

  // Show the Emoji & Sticker Picker as a Bottom Drawer
  void _showEmojiStickerPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return BottomDrawer(
          onEmojiSelected: (emoji) => _sendMessage(text: emoji),
          onStickerSelected: (sticker) => _sendMessage(stickerUrl: sticker),
          onPlayMiniGame: () {
            // Implement play mini game logic
          },
          onShareMusic: () {
            // Implement share music logic
          },
          onTripJournal: () {
            // Implement trip journal logic
          },
          emojiList: _emojiList,
          stickerList: _stickerList,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chat"),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            if (otherUserId != null)
              IconButton(
                icon: const Icon(Icons.flag, color: Colors.red),
                onPressed: _reportUser, // 🔹 Add report button
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _confirmEndChat,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.getMessages(),
                  builder: (context, snapshot) {
                    List<MessageModel> messages = snapshot.data ?? [];

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length + (isOtherUserTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if ((isOtherUserTyping && index == 0) ||
                            (isOtherUserTyping && messages.isEmpty)) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.start, // Align to left
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: AssetImage(
                                    'assets/default_pic.jpg',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const TypingBubble(), // Show typing animation bubble
                              ],
                            ),
                          );
                        }

                        final messageIndex =
                            isOtherUserTyping ? index - 1 : index;
                        MessageModel message = messages[messageIndex];
                        bool isMe = message.senderId == widget.currentUserId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe) // Show profile picture for received messages
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: AssetImage(
                                    'assets/default_pic.jpg',
                                  ),
                                ),
                              const SizedBox(width: 8),

                              // Chat Bubble
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blueAccent : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: message.stickerUrl != null
                                      ? Image.network(
                                          message.stickerUrl!,
                                          height: 100,
                                        )
                                      : Text(
                                          message.text ?? "",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isMe ? Colors.white : Colors.black,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              if (isMe) // Show profile picture for sent messages
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: AssetImage(
                                    'assets/default_pic.jpg',
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showEmojiStickerPicker,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: (text) => _updateTypingStatus(text.isNotEmpty),
                        onSubmitted: (text) {
                          _onMessageSent(); // Reset timer when user sends a message
                        },
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendMessage(text: _messageController.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
