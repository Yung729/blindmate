import 'package:flutter/material.dart';
import '../../models/dataModels/post_model.dart';
import '../dataBinding/sharing_data_binding.dart';
import '../state/sharing_state.dart';
import '../../views/screens/create_post_screen.dart';

class SharingEventHandler {
  final SharingState sharingState;
  final SharingDataBinding dataBinding;

  SharingEventHandler({required this.sharingState, required this.dataBinding});

  /// Initialize the event handler and data binding
  Future<void> init() async {
    await dataBinding.initialize();
  }

  Future<void> navigateToCreatePost(
  BuildContext context, {
  required String userId,
  required String userName,
  required String avatarImg,
}) async {
  final Map<String, dynamic>? newPostData = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CreatePostScreen(
        userId: userId,
        userName: userName,
      ),
    ),
  );

  if (newPostData != null) {
    final newPost = PostModel(
      userId: userId,
      userName: userName,
      content: newPostData['content'] ?? '',
      musicUrl: newPostData['musicUrl'],
      musicTitle: newPostData['musicTitle'],
      visibility: newPostData['visibility'] ?? 'public',
      timestamp: DateTime.now(),
    );
    await dataBinding.createPost(newPost);
  }
}

  Future<void> deletePost(String postId) async{
    await dataBinding.deletePost(postId);
    return;
  }

  Future<void> togglePostVisibility(String postId) async{
    final post = sharingState.posts.firstWhere((p) => p.id == postId);
    final newVisibility = !post.isPublic;
    dataBinding.updatePostVisibility(postId, newVisibility);
    return;
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

  /// Handle hide post action from UI
  Future<void> hidePost(String postId) async {
    await dataBinding.hidePost(postId);
  }

  /// Handle unhide post action from UI
  Future<void> unhidePost(String postId) async {
    await dataBinding.unhidePost(postId);
  }

  List<PostModel> getFilteredPosts({
    required String userId,
    bool myPostsOnly = false,
  }) {
    return dataBinding.getFilteredPosts(
      userId: userId,
      myPostsOnly: myPostsOnly,
    );
  }

  /// Get posts formatted for display
  List<Map<String, dynamic>> getDisplayedPosts({
    required String userId,
    required bool showMyPostsOnly,
    required Set<String> hiddenPostIds,
  }) {
    return dataBinding.getDisplayedPosts(
      userId: userId,
      showMyPostsOnly: showMyPostsOnly,
      hiddenPostIds: hiddenPostIds,
    );
  }
}
