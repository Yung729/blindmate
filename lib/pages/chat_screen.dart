import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/emoji_service.dart';
import '../services/giphy_service.dart';
import '../models/message_model.dart';

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
  final EmojiService _emojiService = EmojiService();
  final GiphyService _giphyService = GiphyService();

  List<String> _emojiList = [];
  List<String> _stickerList = [];
  bool partnerLeft = false;
  bool _isChatOpen = true;
  bool isTyping = false;
  String? otherUserId;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _loadEmojis();
    WidgetsBinding.instance.addObserver(this);
    _fetchChatPartner();
    _startInactivityTimer();

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
    _inactivityTimer = Timer(const Duration(minutes: 1), () {
      _showInactivityDialog();
    });
  }

  Future<void> _showInactivityDialog() async {
    if (!mounted) return;

    bool? shouldExit = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
    bool? shouldEnd = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text(
                  "End Chat",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldEnd == true) {
      _handleExit();
    }
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

    if (users.isEmpty) {
      await _chatService.closeChatRoom(widget.chatRoomId, users);
    } else {
      await chatRef.update({'closed': true});
      await _chatService.updateUserStatus(widget.currentUserId, 'available');
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
        _emojiList = emojis.take(20).toList(); // Show only 20 emojis for now
      });
    } catch (e) {
      print("❌ Failed to load emojis: $e");
    }
  }

  void _loadStickers(String query) async {
    List<String> stickers = await _giphyService.fetchStickers(query);
    setState(() {
      _stickerList = stickers;
    });
  }

  // Show the Emoji & Sticker Picker as a Bottom Drawer
  void _showEmojiStickerPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text("Emoji Picker"),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sticky_note_2),
                title: const Text("Sticker Picker"),
                onTap: () {
                  Navigator.pop(context);
                  _showStickerPicker();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Emoji Picker
  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: _emojiList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _sendMessage(text: _emojiList[index]),
                child: Center(
                  child: Text(
                    _emojiList[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Show Sticker Picker
  void _showStickerPicker() {
    _loadStickers("funny");

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _stickerList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _sendMessage(stickerUrl: _stickerList[index]),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(_stickerList[index], height: 100),
                ),
              );
            },
          ),
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
        body: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null)
                  return const SizedBox();
                var data = snapshot.data!.data() as Map<String, dynamic>;
                Map<String, dynamic>? typing = data['typing'];

                String? otherUserId = typing?.keys.firstWhere(
                  (id) => id != widget.currentUserId,
                  orElse: () => '',
                );

                bool isOtherUserTyping =
                    otherUserId != null && typing?[otherUserId] == true;

                return isOtherUserTyping
                    ? const Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 5),
                      child: Text(
                        "User is typing...",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                    : const SizedBox();
              },
            ),

            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatRoomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  List<MessageModel> messages = snapshot.data!;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      MessageModel message = messages[index];
                      bool isMe = message.senderId == widget.currentUserId;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child:
                            message.stickerUrl != null
                                ? Image.network(
                                  message.stickerUrl!,
                                  height: 100,
                                )
                                : Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isMe
                                            ? Colors.blueAccent
                                            : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    message.text ?? "",
                                    style: const TextStyle(fontSize: 16),
                                  ),
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
                    onPressed:
                        () => _sendMessage(text: _messageController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
