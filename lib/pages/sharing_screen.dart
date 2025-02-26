import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
          _currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
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
      });

      // Clear the input field after sharing
      _textController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Content shared successfully!")),
      );
    }
  }

  void _logout() async {
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.userId).update({
        'online': false,
        'status': 'available',
      });
    }
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sharing Info")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_currentUser != null)
                    Text(
                      "Hello, ${_currentUser!.name}!",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: "Share something...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _shareContent,
                    child: const Text("Share"),
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: _buildSharedContentList()),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text("Logout"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSharedContentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('shared_content').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final sharedPosts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: sharedPosts.length,
          itemBuilder: (context, index) {
            final post = sharedPosts[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(post['userName']),
                subtitle: Text(post['content']),
              ),
            );
          },
        );
      },
    );
  }
}
