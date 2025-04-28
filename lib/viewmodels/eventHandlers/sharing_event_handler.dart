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
  BuildContext context, {
  required String userId,
  required String userName,
  required String avatarImg,
}) async {
  // Construct a UserModel with all required fields
  final user = UserModel(
    userId: userId,
    name: userName,
    avatarImg: avatarImg,
    email: '', // dummy value
    levelValue: 0,
    online: false,
    status: 'active',
    emotionStatus: 'neutral', // dummy value
    progressionValue: 0.0,    // dummy value
    fragmentNumber: 0,        // dummy value
    currentMission: '',       // dummy value
    flower: 0,                // dummy value
    surveyDate: DateTime.now(), // dummy value
    // lastActive: DateTime.now(), // optional
    // hiddenPosts: const [],     // optional
  );

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

  Future<void> updatePostVisibilityInDatabase(
    String postId,
    bool isPublic,
  ) async {
    sharingState.setLoading(true);
    try {
      await _postService.updatePost(postId, {
        'visibility': isPublic ? 'public' : 'private',
      });
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

  List<PostModel> getFilteredPosts({
    required String userId,
    bool myPostsOnly = false,
  }) {
    return myPostsOnly
        ? sharingState.posts
            .where(
              (post) => post.userId == userId && post.visibility != 'deleted',
            )
            .toList()
        : sharingState.posts
            .where((post) => post.visibility != 'deleted')
            .toList();
  }

  List<Map<String, dynamic>> getDisplayedPosts({
    required String userId,
    required bool showMyPostsOnly,
    required Set<String> hiddenPostIds,
  }) {
    // Filter and convert PostModel to Map<String, dynamic>
    final filteredPosts =
        showMyPostsOnly
            ? sharingState.posts.where(
              (post) => post.userId == userId && post.visibility != 'deleted',
            )
            : sharingState.posts.where((post) => post.visibility != 'deleted');

    return filteredPosts.where((post) => !hiddenPostIds.contains(post.id)).map((
      post,
    ) {
      final map = post.toMap();
      map['id'] = post.id;
      map['authorAvatar'] = post.authorAvatar;
      map['timestamp'] = post.timestamp.toIso8601String();
      return map;
    }).toList();
  }
}
