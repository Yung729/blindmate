import 'package:flutter/material.dart';

class PostMusicPreview extends StatelessWidget {
  final String? musicUrl;
  final String? musicTitle;
  final VoidCallback? onPlay;

  const PostMusicPreview({
    Key? key,
    required this.musicUrl,
    required this.musicTitle,
    this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videoId = musicUrl != null && musicUrl!.isNotEmpty
        ? Uri.tryParse(musicUrl!)?.queryParameters['v'] ?? ''
        : '';
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.grey[200],
        ),
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
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
                      "Tap to play",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
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
}