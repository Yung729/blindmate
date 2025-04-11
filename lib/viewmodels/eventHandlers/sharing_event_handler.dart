import 'package:flutter/material.dart';
import '../../models/dataModels/post_model.dart'; // Import the merged PostModel
import '../../models/dataModels/user_model.dart';
import '../dataBinding/sharing_data_binding.dart';
import '../state/sharing_state.dart';
import '../../services/post_service.dart'; // Import the merged PostService
import '../../views/screens/create_post_screen.dart';

class SharingEventHandler {
  final SharingState sharingState;
  final SharingDataBinding dataBinding;
  final PostService _postService = PostService(); // Use the merged service

  SharingEventHandler({required this.sharingState, required this.dataBinding});

  Future<void> init() async {
    await dataBinding.initialize();
  }

  Future<void> navigateToCreatePost(
    BuildContext context,
    UserModel user,
  ) async {
    final Map<String, dynamic>? newPostData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostScreen(user: user)),
    );

    if (newPostData != null) {
      final newPost = PostModel(
        userId: user.userId,
        userName: user.name, // Assuming user model has 'name'
        content: newPostData['content'] ?? '',
        musicUrl: newPostData['musicUrl'],
        musicTitle: newPostData['musicTitle'], // Assuming this is passed back
        visibility: newPostData['visibility'] ?? 'public',
        timestamp: DateTime.now(),
      );
      await _postService.createPost(newPost);
    }
  }

  void deletePost(String postId) {
    // No longer just local state update, now triggers database deletion
    deletePostFromDatabase(postId);
    // The state will be updated by the stream
  }

  Future<void> deletePostFromDatabase(String postId) async {
    sharingState.setLoading(true);
    try {
      await _postService.deletePost(postId);
      // The state will be updated automatically by the stream in SharingDataBinding
    } catch (e) {
      print("Error deleting post: $e");
      // Handle error appropriately, e.g., show a snackbar
    } finally {
      sharingState.setLoading(false);
    }
  }

  void togglePostVisibility(String postId) {
    final post = sharingState.posts.firstWhere((p) => p.id == postId);
    final newVisibility = !post.isPublic;
    updatePostVisibilityInDatabase(postId, newVisibility);
    // The local state will be updated by the stream
  }

  Future<void> updatePostVisibilityInDatabase(String postId, bool isPublic) async {
    sharingState.setLoading(true);
    try {
      await _postService.updatePost(postId, {'visibility': isPublic ? 'public' : 'private'});
      // The state will be updated automatically by the stream
    } catch (e) {
      print("Error updating post visibility: $e");
      // Handle error appropriately
    } finally {
      sharingState.setLoading(false);
    }
  }

  void playMusic(String youtubeUrl) {
    dataBinding.setCurrentMusicUrl(youtubeUrl);
  }

  void closeMusic() {
    dataBinding.setCurrentMusicUrl(null);
  }

  String? getYouTubeVideoId(String url) {
    return dataBinding.extractYouTubeVideoId(url);
  }

  String? getUrlFromContent(String content) {
    return dataBinding.extractUrlFromContent(content);
  }
}