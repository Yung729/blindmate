import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/user_model.dart';
import 'create_post_screen.dart';
import 'music_player_screen.dart';

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

  void _navigateToCreatePost() async {
    final newPost = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(user: widget.user),
      ),
    );

    if (newPost != null) {
      await _firestore.collection('shared_content').add(newPost);
    }
  }

  Future<void> _deletePost(String postId) async {
    await _firestore.collection('shared_content').doc(postId).delete();
  }

  Future<void> _toggleVisibility(
    String postId,
    String currentVisibility,
  ) async {
    String newVisibility = currentVisibility == 'public' ? 'private' : 'public';
    await _firestore.collection('shared_content').doc(postId).update({
      'visibility': newVisibility,
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sharing")),
      body: Column(
        children: [
          _buildCreatePostButton(),
          Expanded(child: _buildSharedContentList()),
        ],
      ),
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
              onTap: _navigateToCreatePost,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
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
      stream:
          _firestore
              .collection('shared_content')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sharedPosts =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['visibility'] == 'public' ||
                  data['userId'] == _currentUser?.userId;
            }).toList();

        return ListView.builder(
          itemCount: sharedPosts.length,
          itemBuilder: (context, index) {
            final post = sharedPosts[index];
            final postId = post.id;
            final data = post.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate =
                timestamp != null
                    ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(timestamp.toDate())
                    : "Unknown date";

            bool isCurrentUserPost = data['userId'] == _currentUser?.userId;
            String? videoId = _extractYouTubeVideoId(data['musicUrl'] ?? "");

            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/default_pic.jpg'),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Anonymous User",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (isCurrentUserPost) ...[
                        IconButton(
                          icon: const Icon(Icons.lock_outline),
                          onPressed:
                              () =>
                                  _toggleVisibility(postId, data['visibility']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePost(postId),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (data['content'] != null && data['content'].isNotEmpty)
                    Text(data['content']),
                  const SizedBox(height: 8),
                  if (videoId != null)
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MusicPlayerScreen(
                                    youtubeUrl: data['musicUrl'],
                                  ),
                            ),
                          ),
                      child: Column(
                        children: [
                          Image.network(
                            "https://img.youtube.com/vi/$videoId/0.jpg",
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "🎵 Play Music",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
