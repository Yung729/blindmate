import 'package:blindmate/views/UIComponents/trip_journal_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './persistent_youtube_player.dart';

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
  final List<Map<String, dynamic>>? tripJournals;

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
    this.tripJournals,
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

    // Use a post-frame callback to ensure the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    bool isMusicMessage = widget.musicUrl != null && widget.musicUrl!.isNotEmpty;
    bool isTripJournal = widget.tripJournals != null && widget.tripJournals!.isNotEmpty;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isMe)
                  Container(
                    width: 36,
                    margin: EdgeInsets.only(right: 8),
                    child: widget.showAvatar ? _buildAvatar() : null,
                  ),
                  
                SizedBox(width: screenWidth * 0.02),
                
                Flexible(
                  child: Column(
                    crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                     
                      if (isMusicMessage)
                        _buildMusicContent(context)
                      else if (isTripJournal) 
                        _buildTripJournalContent()
                      else
                        Container(
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTimestamp(widget.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (widget.moderationStatus == 'UNSAFE' || widget.moderationStatus == 'WARNING')
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: widget.moderationStatus == 'UNSAFE' ? Colors.red[100] : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.moderationStatus == 'UNSAFE' ? Icons.warning_amber_rounded : Icons.info_outline,
                                          size: 10,
                                          color: widget.moderationStatus == 'UNSAFE' ? Colors.red : Colors.orange,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          widget.moderationStatus == 'UNSAFE' ? 'Flagged' : 'Warning',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: widget.moderationStatus == 'UNSAFE' ? Colors.red : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.02),
                
                if (widget.isMe)
                  Container(
                    width: 36,
                    margin: EdgeInsets.only(left: 8),
                    child: widget.showAvatar ? _buildAvatar() : null,
                  ),
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
    if (widget.musicUrl != null && widget.musicUrl!.isNotEmpty) {
      // Create a unique key based on the music URL
      final playerKey = ValueKey('music-${widget.musicUrl}');
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: PersistentYoutubePlayer(
          youtubeUrl: widget.musicUrl!,
          title: widget.musicTitle,
          playerKey: playerKey,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTripJournalContent() {
    if (widget.tripJournals != null && widget.tripJournals!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: TripJournalBookCard(journals: widget.tripJournals!),
      );
    }
    return const SizedBox.shrink();
  }
}
