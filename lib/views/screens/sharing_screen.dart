import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_screen.dart';
import '../../models/dataModels/user_model.dart';
import '../UIComponents/floating_music_player.dart';
import '../UIComponents/fetch_url_thumbail.dart';

class SharingScreen extends StatefulWidget {
  final UserModel user;

  const SharingScreen({super.key, required this.user});

  @override
  _SharingScreenState createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;
  String? _currentMusicUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
            userDoc.id,
          );
        });
      }
    }
  }

  void _playMusic(String youtubeUrl) {
    setState(() {
      _currentMusicUrl = youtubeUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("A Space For People To Share Thoughts!"),
          ),
          body: Column(
            children: [
              _buildCreatePostButton(),
              Expanded(child: _buildSharedContentList()),
            ],
          ),
        ),

        if (_currentMusicUrl != null)
          FloatingMusicPlayer(
            youtubeUrl: _currentMusicUrl!,
            onClose: () {
              setState(() {
                _currentMusicUrl = null;
              });
            },
          ),
      ],
    );
  }

Widget _buildCreatePostButton() {
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundImage: AssetImage('assets/default_pic.jpg'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final newPost = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePostScreen(user: widget.user),
                ),
              );

              if (newPost != null) {
                await _firestore.collection('shared_content').add(newPost);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "What's on your mind?",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildSharedContentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('shared_content').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sharedPosts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['visibility'] == 'public' || data['userId'] == _currentUser?.userId;
        }).toList();

        return ListView.builder(
          itemCount: sharedPosts.length,
          itemBuilder: (context, index) {
            final post = sharedPosts[index];
            final data = post.data() as Map<String, dynamic>;
            final videoId = _extractYouTubeVideoId(data['musicUrl'] ?? "");

            // Extract general URL from content
            RegExp urlRegExp = RegExp(
              r'(https?:\/\/[^\s]+)',
              caseSensitive: false,
            );
            Match? urlMatch = urlRegExp.firstMatch(data['content'] ?? '');
            String? detectedUrl = urlMatch?.group(0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/default_pic.jpg'),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Depression People",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (data['content'] != null && data['content'].isNotEmpty)
                    Text(data['content']),

                  const SizedBox(height: 8),

                  if (videoId != null)
                    GestureDetector(
                      onTap: () => _playMusic(data['musicUrl']),
                      child: Column(
                        children: [
                          Image.network("https://img.youtube.com/vi/$videoId/0.jpg"),
                          const SizedBox(height: 4),
                          const Text("🎵 Play Music", style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),

                  if (detectedUrl != null && videoId == null)
                    buildLinkPreview(detectedUrl),

                  const Divider(),
                ],
              ),
            );
          },
        );
      },
    );
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
}
