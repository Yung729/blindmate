import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class SharingScreen extends StatefulWidget {
  final UserModel user;

  const SharingScreen({super.key, required this.user});

  @override
  _SharingScreenState createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _currentUser = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
            userDoc.id,
          );
          _isLoading = false;
        });
      }
    }
  }

  void _shareContent() async {
    if (_currentUser != null && _textController.text.isNotEmpty) {
      await _firestore.collection('shared_content').add({
        'userId': _currentUser!.userId,
        'userName': _currentUser!.name,
        'content': _textController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'visibility': _isPublic ? 'public' : 'private',
      });
      _textController.clear();
    }
  }

  Future<void> _toggleLike(String postId, List<dynamic> likes) async {
    final userId = _currentUser?.userId;
    if (userId == null) return;

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    await _firestore.collection('shared_content').doc(postId).update({
      'likes': likes,
    });
  }

  Future<void> _deletePost(String postId) async {
    await _firestore.collection('shared_content').doc(postId).delete();
  }

  Future<void> _toggleVisibility(
      String postId,
      String? currentVisibility,
      ) async {
    if (currentVisibility == null) {
      currentVisibility = 'public'; // Default to 'public' if null
    }

    String? newVisibility = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Change Visibility"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Public"),
                leading: Radio<String>(
                  value: 'public',
                  groupValue: currentVisibility,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
              ListTile(
                title: const Text("Private"),
                leading: Radio<String>(
                  value: 'private',
                  groupValue: currentVisibility,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (newVisibility != null && newVisibility != currentVisibility) {
      await _firestore.collection('shared_content').doc(postId).update({
        'visibility': newVisibility,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _buildSharedContentList()),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildSharedContentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('shared_content')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sharedPosts = snapshot.data!.docs.where((doc) {
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
            final likes = List<String>.from(data['likes'] ?? []);
            final isLiked =
                _currentUser != null && likes.contains(_currentUser!.userId);
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                : "Unknown date";
            final visibility = (data['visibility'] ?? 'public') as String;
            final isOwner = data['userId'] == _currentUser?.userId;

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
                      Text(
                        data['userName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isOwner)
                        IconButton(
                          icon: Icon(
                            visibility == 'public' ? Icons.lock_open : Icons.lock,
                            color: Colors.grey,
                          ),
                          onPressed: () => _toggleVisibility(postId, visibility),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data['content']),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleLike(postId, likes),
                      ),
                      Text("${likes.length}"),
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePost(postId),
                        ),
                    ],
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

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: "Say something...",
                border: InputBorder.none,
              ),
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: _shareContent,
          ),
        ],
      ),
    );
  }
}