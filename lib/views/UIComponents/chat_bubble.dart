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
    // Check if this is a music message
    bool isMusicMessage = musicUrl != null && musicUrl!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar on the left for other user's messages
          if (!isMe)
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/default_pic.jpg'),
            ),
          const SizedBox(width: 8),
          
          // Content - either text/sticker bubble or music
          Flexible(
            child: isMusicMessage 
              ? _buildMusicContent(context) // Show music content
              : Container( // Show regular bubble with text/sticker
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
                  child: _buildContent(),
                ),
          ),
          
          const SizedBox(width: 8),
          
          // Avatar on the right for user's messages
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
