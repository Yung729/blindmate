import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/youtube_api.dart';

class CreatePostScreen extends StatefulWidget {
  final UserModel user;

  const CreatePostScreen({super.key, required this.user});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _musicController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;
  List<Map<String, String>> _musicResults = [];
  String? _selectedMusicUrl;
  String? _selectedMusicTitle; // Store song title separately

  void _fetchYouTubeMusic() async {
    String query = _musicController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    List<Map<String, String>> results = await YouTubeAPI.searchYouTubeMusicList(query);

    setState(() {
      _isLoading = false;
      _musicResults = results;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No songs found! Try a different search.")),
      );
    }
  }

  void _sharePost() async {
    if (_textController.text.trim().isEmpty && _selectedMusicUrl == null) return;

    final newPost = {
      'userId': widget.user.userId,
      'userName': widget.user.name,
      'content': _textController.text.trim(),
      'musicUrl': _selectedMusicUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'visibility': _isPublic ? 'public' : 'private',
    };

    Navigator.pop(context, newPost);
  }

  void _shareMusic() {
    if (_selectedMusicUrl != null) {
      Share.share("Check out this song: $_selectedMusicUrl");
    }
  }

  Future<void> _launchURL() async {
    if (_selectedMusicUrl != null) {
      final Uri url = Uri.parse(_selectedMusicUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the link.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _musicController,
              onChanged: (text) => _fetchYouTubeMusic(),
              decoration: const InputDecoration(
                hintText: "Enter song name to search on YouTube",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            if (_musicResults.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: _musicResults.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_musicResults[index]['title']!),
                      onTap: () {
                        setState(() {
                          _selectedMusicUrl = _musicResults[index]['url'];
                          _selectedMusicTitle = _musicResults[index]['title'];
                          _musicResults.clear(); // Hide search results after selection
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            // Show selected song with the song name as a clickable link
            if (_selectedMusicUrl != null) ...[
              const Text("Selected Song:"),
              InkWell(
                onTap: _launchURL, // Opens YouTube link when clicked
                child: Text(
                  _selectedMusicTitle ?? "Click here to listen",
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Public"),
                Switch(
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sharePost,
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}
