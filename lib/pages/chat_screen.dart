import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/emoji_service.dart';
import '../services/giphy_service.dart';
import '../models/message_model.dart';
import 'home_screen.dart';

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
  bool _isEmojiPickerVisible = false;
  bool _isStickerPickerVisible = false;
  List<String> _emojiList = [];
  List<String> _stickerList = [];
  bool partnerLeft = false;
  bool _isChatOpen = true;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadEmojis();
    WidgetsBinding.instance.addObserver(this);

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
      _isStickerPickerVisible = !_isStickerPickerVisible; // Toggle picker
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    super.dispose();
  }

  // Detect app lifecycle changes (Close chat when app is closed)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _handleExit();
    }
  }

  // Handle closing the chat room
  Future<void> _handleExit({bool isManualClose = false}) async {
    if (!_isChatOpen) return;
    _isChatOpen = false;

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .get();

    if (chatDoc.exists) {
      List<String> users = List<String>.from(chatDoc['users']);
      users.remove(widget.currentUserId);

      if (users.isEmpty || isManualClose) {
        await _chatService.closeChatRoom(widget.chatRoomId, users);
      } else {
        await _chatService.updateUserStatus(widget.currentUserId, 'available');
      }
    }

    if (isManualClose) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _sendMessage({String? text, String? stickerUrl}) {
    if ((text == null || text.trim().isEmpty) && (stickerUrl == null || stickerUrl.isEmpty)) {
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

    setState(() {
      _isStickerPickerVisible = false;
      _isEmojiPickerVisible = false;
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
      _isStickerPickerVisible = false; // Hide stickers if emojis are opened
    });
  }

  void _toggleStickerPicker() {
    _loadStickers("funny"); // Load stickers with a default query
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
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                await _handleExit(isManualClose: true);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatRoomId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
                var data = snapshot.data!.data() as Map<String, dynamic>;
                Map<String, dynamic>? typing = data['typing'];

                String? otherUserId = typing?.keys.firstWhere(
                  (id) => id != widget.currentUserId,
                  orElse: () => '',
                );

                bool isOtherUserTyping = otherUserId != null && typing?[otherUserId] == true;

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
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  List<MessageModel> messages = snapshot.data!;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      MessageModel message = messages[index];
                      bool isMe = message.senderId == widget.currentUserId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: message.stickerUrl != null
                            ? Image.network(message.stickerUrl!, height: 100)
                            : Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blueAccent : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(message.text ?? "", style: const TextStyle(fontSize: 16)),
                              ),
                      );
                    },
                  );
                },
              ),
            ),

            if (_isStickerPickerVisible)
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _stickerList.map((sticker) {
                    return GestureDetector(
                      onTap: () => _sendMessage(stickerUrl: sticker),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(sticker, height: 80),
                      ),
                    );
                  }).toList(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.emoji_emotions_outlined), onPressed: _toggleEmojiPicker),
                  IconButton(icon: const Icon(Icons.sticky_note_2), onPressed: _toggleStickerPicker),
                  Expanded(child: TextField(controller: _messageController, onChanged: (text) => _updateTypingStatus(text.isNotEmpty))),
                  IconButton(icon: const Icon(Icons.send), onPressed: () => _sendMessage(text: _messageController.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
