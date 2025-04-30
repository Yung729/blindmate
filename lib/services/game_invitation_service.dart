import 'package:cloud_firestore/cloud_firestore.dart';

class GameInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> sendInvitation({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String gameType,
  }) async {
    final docRef = await _firestore.collection('game_invitations').add({
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'receiverId': receiverId,
      'gameType': gameType,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> respondToInvitation(String invitationId, bool accepted) async {
    await _firestore.collection('game_invitations').doc(invitationId).update({
      'status': accepted ? 'accepted' : 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _firestore.collection('game_invitations').doc(invitationId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> listenForInvitations(String userId) {
    return _firestore
        .collection('game_invitations')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> listenForInvitationResponse(String userId) {
    return _firestore
        .collection('game_invitations')
        .where('senderId', isEqualTo: userId)
        .where('status', whereIn: ['accepted', 'declined', 'cancelled'])
        .snapshots();
  }

  Stream<QuerySnapshot> listenForInvitationCancellation(String userId) {
    return _firestore
        .collection('game_invitations')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'cancelled')
        .snapshots();
  }

  Future<void> deleteInvitation(String invitationId) async {
    await _firestore.collection('game_invitations').doc(invitationId).delete();
  }
} 