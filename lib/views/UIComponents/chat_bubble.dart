import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/chat_state.dart';
import './music_overlay_manager.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String? text;
  final String? stickerUrl;
  final String? musicUrl;
  final String? musicTitle;
  final Widget? child;

  const ChatBubble({
    Key? key,
    required this.isMe,
    this.text,
    this.stickerUrl,
    this.musicUrl,
    this.musicTitle,
    this.child,
  }) : super(key: key);
  


  @override
  Widget build(BuildContext context) {
    bool isMusicMessage = musicUrl != null && musicUrl!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleMaxWidth = screenWidth * 0.7;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.008 + 1,
        horizontal: screenWidth * 0.015 + 4,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/default_pic.jpg'),
            ),
          SizedBox(width: screenWidth * 0.02 + 4),
          Flexible(
            child: isMusicMessage
                ? _buildMusicContent(context)
                : Container(
                    constraints: BoxConstraints(
                      maxWidth: bubbleMaxWidth,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenWidth * 0.015 + 4,
                      horizontal: screenWidth * 0.03 + 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFF8FFAE), Color(0xFF43C6AC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 16 : 4),
                        topRight: Radius.circular(isMe ? 4 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: _buildContent(),
                  ),
          ),
          SizedBox(width: screenWidth * 0.02 + 4),
          if (isMe)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/default_pic.jpg'),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Child widget takes precedence if provided
    if (child != null) return child!;

    // Sticker has next priority
    if (stickerUrl != null && stickerUrl!.isNotEmpty) {
      return Image.network(
        stickerUrl!,
        height: 100,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print("❌ Error loading sticker: $error");
          return const Icon(Icons.broken_image, size: 100);
        },
      );
    }

    // Default to text
    return Text(
      text ?? "",
      style: TextStyle(color: isMe ? Colors.white : Colors.black),
    );
  }
  
  // New method to build music content separately
  Widget _buildMusicContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (musicUrl != null && musicUrl!.isNotEmpty) {
          // Get the ChatState
          final chatState = Provider.of<ChatState>(context, listen: false);
          
          // Set music as playing in the ChatState
          chatState.setMusicPlaying(true);
          
          // Use the MusicOverlayManager to play the music
          MusicOverlayManager().playMusic(context, musicUrl!);
        }
      },
      child: Container(
        width: 250, // Fixed width for consistency
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Color(0xFFE3F2FD),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMusicThumbnail(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    musicTitle ?? "Untitled",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Tap to play",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.blue,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMusicThumbnail() {
    final videoId = musicUrl != null && musicUrl!.isNotEmpty
        ? Uri.tryParse(musicUrl!)?.queryParameters['v'] ?? ''
        : '';
        
    return SizedBox(
      width: 60,
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          "http://img.youtube.com/vi/$videoId/mqdefault.jpg",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.music_note,
                size: 30,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }
}
