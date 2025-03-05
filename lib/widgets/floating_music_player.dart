import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../pages/music_player_screen.dart'; // Import the full-screen player screen

class FloatingMusicPlayer extends StatefulWidget {
  final String youtubeUrl;
  final VoidCallback onClose;

  const FloatingMusicPlayer({
    super.key,
    required this.youtubeUrl,
    required this.onClose,
  });

  @override
  _FloatingMusicPlayerState createState() => _FloatingMusicPlayerState();
}

class _FloatingMusicPlayerState extends State<FloatingMusicPlayer> {
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController(
      initialVideoId: _extractYouTubeVideoId(widget.youtubeUrl)!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  String? _extractYouTubeVideoId(String url) {
    RegExp regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?/ ]{11})',
      caseSensitive: false,
      multiLine: false,
    );
    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _openFullScreenPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerScreen(youtubeUrl: widget.youtubeUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, // No gap above navigation bar
      right: 10, // Position slightly inside from the edge
      child: Container(
        width: 270, // Small width, like YouTube's mini player
        height: 150, // Fixed height
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: YoutubePlayer(controller: _youtubeController),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: widget.onClose,
              ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                onPressed: _openFullScreenPlayer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
