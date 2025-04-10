import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dataModels/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPost(PostModel post) async {
    await _firestore.collection('shared_content').add(post.toMap());
  }

  Stream<List<PostModel>> getPosts(String userId) {
    return _firestore
        .collection('shared_content')
        .where('visibility', isEqualTo: 'public')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}