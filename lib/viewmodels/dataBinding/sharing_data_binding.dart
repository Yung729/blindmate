import '../../services/post_service.dart';
import '../state/sharing_state.dart';

class SharingDataBinding {
  final PostService _postService = PostService();
  final SharingState sharingState;

  SharingDataBinding({required this.sharingState});

  Future<void> initialize() async {
    sharingState.setLoading(true);

    // Load user data
    final userData = await _postService.loadUserData();
    if (userData != null) {
      // Await setCurrentUser to ensure hidden posts are loaded before posts stream
      await sharingState.setCurrentUser(userData);
    }

    // Set up stream for posts
    if (sharingState.currentUser != null) {
      _postService.getPosts(sharingState.currentUser!.userId).listen((
        posts,
      ) async {
        // 1. Collect unique userIds from posts
        final userIds = posts.map((p) => p.userId).toSet().toList();

        // 2. Fetch avatars for all userIds
        final avatarMap = await _postService.fetchAvatarsForUserIds(userIds);

        // 3. Attach avatar to each post (assumes PostModel has authorAvatar field)
        for (final post in posts) {
          // If you have authorAvatar in PostModel, set it here:
          // post.authorAvatar = avatarMap[post.userId];
          // If not, you can use avatarMap in your UI instead.
          // Only set if the field exists
          try {
            post.authorAvatar = avatarMap[post.userId];
          } catch (_) {}
        }

        sharingState.setPosts(posts);
        sharingState.setLoading(false);
      });
    } else {
      sharingState.setLoading(false);
    }
  }

  /// Optionally, expose a method to refresh hidden posts from Firestore
  Future<void> refreshHiddenPosts() async {
    if (sharingState.currentUser != null) {
      final hiddenIds = await _postService.getHiddenPosts();
      sharingState.setHiddenPostIds(hiddenIds.toSet());
    }
  }

  Future<void> deletePost(String postId) async {
    sharingState.setLoading(true);
    try {
      await _postService.deletePost(postId);
      // The stream in initialize should handle updating the state automatically
    } catch (e) {
      print("Error deleting post via service: $e");
      sharingState.setLoading(false);
    } finally {
      if (sharingState.isLoading) {
        sharingState.setLoading(false);
      }
    }
  }

  Future<void> updatePostVisibility(String postId, bool isPublic) async {
    sharingState.setLoading(true);
    try {
      await _postService.updatePost(postId, {
        'visibility': isPublic ? 'public' : 'private',
      });
      // The stream in initialize should handle updating the state automatically
    } catch (e) {
      print("Error updating post visibility via service: $e");
      sharingState.setLoading(false);
    } finally {
      if (sharingState.isLoading) {
        sharingState.setLoading(false);
      }
    }
  }

  String? extractYouTubeVideoId(String url) {
    return _postService.extractYouTubeVideoId(url);
  }

  String? extractUrlFromContent(String content) {
    return _postService.extractUrlFromContent(content);
  }

  void setCurrentMusicUrl(String? url) {
    sharingState.setCurrentMusicUrl(url);
  }
}
