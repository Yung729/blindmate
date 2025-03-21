import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/youtube_api.dart';  // Import YouTube API

class MusicButton extends StatefulWidget {
  final String platform; // "YouTube" or "Deezer"
  final String songQuery;

  const MusicButton({required this.platform, required this.songQuery, Key? key}) : super(key: key);

  @override
  _MusicButtonState createState() => _MusicButtonState();
}

class _MusicButtonState extends State<MusicButton> {
  bool isLoading = false;

void fetchAndShareMusic() async {
  setState(() {
    isLoading = true;
  });

  List<Map<String, String>>? searchResults;
  if (widget.platform == "YouTube") {
    searchResults = await YouTubeAPI.searchYouTubeMusicList(widget.songQuery);
  }

  setState(() {
    isLoading = false;
  });

  if (searchResults != null && searchResults.isNotEmpty) {
    String musicUrl = searchResults.first['url']!;
    Share.share("Check out this song: $musicUrl");
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Song not found! Try a different search.")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : fetchAndShareMusic,
      child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Share ${widget.platform} Music"),
    );
  }
}
