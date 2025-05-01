import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/music_player_state.dart';

class PostMusicPreview extends StatelessWidget {
  final String? musicUrl;
  final String? musicTitle;

  const PostMusicPreview({
    Key? key,
    required this.musicUrl,
    required this.musicTitle,
  }) : super(key: key);

  String? extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    // Try to extract from various YouTube URL formats
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ??
          RegExp(r'/embed/([^/?]+)').firstMatch(uri.path)?.group(1);
    }
    // Fallback: try to extract with regex
    final match = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11})').firstMatch(url);
    return match != null ? match.group(1) : null;
  }

  @override
  Widget build(BuildContext context) {
    final videoId = extractYoutubeId(musicUrl);
    final musicState = context.watch<MusicPlayerState>();
    final isPlaying = musicState.currentMusicUrl == musicUrl && musicState.isPlaying;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: isPlaying ? const Color(0xFFBBDEFB) : const Color(0xFFE3F2FD),
        border: isPlaying
            ? Border.all(color: Colors.blueAccent, width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: videoId != null
                  ? Image.network(
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
                    )
                  : Container(
                      color: Colors.black12,
                      child: const Center(
                        child: Icon(
                          Icons.music_note,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),
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
                if (musicUrl != null)
                  Text(
                    isPlaying ? "Now Playing" : "Music",
                    style: TextStyle(
                      color: isPlaying ? Colors.blueAccent : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: isPlaying ? Colors.blueAccent : Colors.blueGrey,
              size: 36,
            ),
            onPressed: () {
              if (musicUrl != null) {
                if (isPlaying) {
                  context.read<MusicPlayerState>().pauseMusic();
                } else {
                  context.read<MusicPlayerState>().playMusic(musicUrl!, musicTitle);
                }
              }
            },
            tooltip: isPlaying ? "Pause" : "Play",
          ),
        ],
      ),
    );
  }
}
