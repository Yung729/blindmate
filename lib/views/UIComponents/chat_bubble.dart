import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/chat_state.dart';
import './music_overlay_manager.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatefulWidget {
  final bool isMe;
  final String? text;
  final String? stickerUrl;
  final String? musicUrl;
  final String? musicTitle;
  final Widget? child;
  final String? avatarUrl;
  final DateTime? timestamp;
  final bool showAvatar;
  final String? moderationStatus;

  const ChatBubble({
    Key? key,
    required this.isMe,
    this.text,
    this.stickerUrl,
    this.musicUrl,
    this.musicTitle,
    this.child,
    this.avatarUrl,
    this.timestamp,
    this.showAvatar = true,
    this.moderationStatus,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('HH:mm').format(timestamp);
  }

  LinearGradient _getGradientForMessage() {
    if (widget.moderationStatus == 'UNSAFE') {
      return const LinearGradient(
        colors: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.moderationStatus == 'WARNING') {
      return const LinearGradient(
        colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    
    return widget.isMe
        ? const LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  Widget _buildModerationIndicator() {
    if (widget.moderationStatus == 'UNSAFE') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red[700]),
            const SizedBox(width: 4),
            Text(
              'This message may be inappropriate',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (widget.moderationStatus == 'WARNING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
            const SizedBox(width: 4),
            Text(
              'Please be mindful of your language',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    bool isMusicMessage = widget.musicUrl != null && widget.musicUrl!.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleMaxWidth = screenWidth * 0.7;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => FadeTransition(
        opacity: _fadeAnimation,
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.008 + 1,
              horizontal: screenWidth * 0.015 + 4,
            ),
            child: Row(
              mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isMe && widget.showAvatar)
                  _buildAvatar()
                else if (!widget.isMe)
                  SizedBox(width: 44),
                  
                SizedBox(width: screenWidth * 0.02),
                
                Flexible(
                  child: Column(
                    crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (widget.moderationStatus == 'UNSAFE' || widget.moderationStatus == 'WARNING')
                        _buildModerationIndicator(),
                      isMusicMessage
                          ? _buildMusicContent(context)
                          : Container(
                              constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                              padding: EdgeInsets.symmetric(
                                vertical: screenWidth * 0.015 + 4,
                                horizontal: screenWidth * 0.03 + 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: _getGradientForMessage(),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(widget.isMe ? 16 : 4),
                                  topRight: Radius.circular(widget.isMe ? 4 : 16),
                                  bottomLeft: const Radius.circular(16),
                                  bottomRight: const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _buildContent(),
                            ),
                      if (widget.timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTimestamp(widget.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.02),
                
                if (widget.isMe && widget.showAvatar)
                  _buildAvatar()
                else if (widget.isMe)
                  SizedBox(width: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
            ? NetworkImage(widget.avatarUrl!)
            : const AssetImage('assets/default_pic.jpg') as ImageProvider,
      ),
    );
  }

  Widget _buildContent() {
    if (widget.child != null) return widget.child!;

    if (widget.stickerUrl != null && widget.stickerUrl!.isNotEmpty) {
      return Image.network(
        widget.stickerUrl!,
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

    return Text(
      widget.text ?? "",
      style: TextStyle(color: widget.isMe ? Colors.white : Colors.black),
    );
  }

  Widget _buildMusicContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.musicUrl != null && widget.musicUrl!.isNotEmpty) {
          final chatState = Provider.of<ChatState>(context, listen: false);
          chatState.setMusicPlaying(true);
          MusicOverlayManager().playMusic(context, widget.musicUrl!);
        }
      },
      child: Container(
        width: 250,
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
                    widget.musicTitle ?? "Untitled",
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
    final videoId = widget.musicUrl != null && widget.musicUrl!.isNotEmpty
        ? Uri.tryParse(widget.musicUrl!)?.queryParameters['v'] ?? ''
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
