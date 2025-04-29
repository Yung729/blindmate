
import 'package:flutter/material.dart';

class PostMusicPreview extends StatelessWidget {
  final String? musicUrl;
  final String? musicTitle;

  const PostMusicPreview({
    Key? key,
    required this.musicUrl,
    required this.musicTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videoId = musicUrl != null && musicUrl!.isNotEmpty
        ? Uri.tryParse(musicUrl!)?.queryParameters['v'] ?? ''
        : '';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: const Color(0xFFE3F2FD),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0), // Rounded corners for image
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
                    "Music",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
