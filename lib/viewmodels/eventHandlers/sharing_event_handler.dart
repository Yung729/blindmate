
import 'package:flutter/material.dart';
import '../../models/dataModels/post_model.dart';
import '../../models/dataModels/user_model.dart';
import '../dataBinding/sharing_data_binding.dart';
import '../state/sharing_state.dart';
import '../../services/post_service.dart';
import '../../views/screens/create_post_screen.dart';

class SharingEventHandler {
  final SharingState sharingState;
  final SharingDataBinding dataBinding;
  final PostService _postService = PostService();

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
        userName: user.name,
        content: newPostData['content'] ?? '',
        musicUrl: newPostData['musicUrl'],
        musicTitle: newPostData['musicTitle'],
        visibility: newPostData['visibility'] ?? 'public',
        timestamp: DateTime.now(),
      );
      await _postService.createPost(newPost);
    }
  }

  void deletePost(String postId) {
    deletePostFromDatabase(postId);
  }

  Future<void> deletePostFromDatabase(String postId) async {
    sharingState.setLoading(true);
    try {
      await _postService.deletePost(postId);
    } catch (e) {
      print("Error deleting post: $e");
    } finally {
      sharingState.setLoading(false);
    }
  }

  void togglePostVisibility(String postId) {
    final post = sharingState.posts.firstWhere((p) => p.id == postId);
    final newVisibility = !post.isPublic;
    updatePostVisibilityInDatabase(postId, newVisibility);
  }

  Future<void> updatePostVisibilityInDatabase(String postId, bool isPublic) async {
    sharingState.setLoading(true);
    try {
      await _postService.updatePost(postId, {'visibility': isPublic ? 'public' : 'private'});
    } catch (e) {
      print("Error updating post visibility: $e");
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

  /// Hide a post for the current user (persistent)
  Future<void> hidePost(String postId) async {
    await sharingState.hidePost(postId);
  }

  /// Unhide a post for the current user (persistent)
  Future<void> unhidePost(String postId) async {
    await sharingState.unhidePost(postId);
  }
}
