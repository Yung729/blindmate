import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class WaitingScreen extends StatefulWidget {
  final String userId;

  const WaitingScreen({super.key, required this.userId});

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _findOrWaitForMatch();
  }

  Future<void> _findOrWaitForMatch() async {
    final userDoc = await _firestore.collection('users').doc(widget.userId).get();
    final int userMentalLevel = userDoc['mentalHealthLevel'] ?? 1;

    final querySnapshot = await _firestore
        .collection('waitingList')
        .where('userId', isNotEqualTo: widget.userId)
        .where('mentalHealthLevel', isLessThanOrEqualTo: userMentalLevel)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final matchedUser = querySnapshot.docs.first;
      String matchedUserId = matchedUser['userId'];
      String chatRoomId = _firestore.collection('chats').doc().id;

      await _firestore.collection('chats').doc(chatRoomId).set({
        'users': [widget.userId, matchedUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'closed': false,
      });

      await _firestore.collection('waitingList').doc(widget.userId).update({'chatRoomId': chatRoomId});
      await _firestore.collection('waitingList').doc(matchedUserId).update({'chatRoomId': chatRoomId});
    } else {
      await _firestore.collection('waitingList').doc(widget.userId).set({
        'userId': widget.userId,
        'mentalHealthLevel': userMentalLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    _listenForMatch();
  }

  void _listenForMatch() {
    _firestore.collection('waitingList').doc(widget.userId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data != null && data.containsKey('chatRoomId')) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoomId: data['chatRoomId']),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Searching for a Match...")),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
