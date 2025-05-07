import '../../services/post_service.dart';
import '../state/sharing_state.dart';
import '../../models/dataModels/post_model.dart';

/// SharingDataBinding handles all data operations and state updates
/// It acts as the bridge between services and state
class SharingDataBinding {
  final PostService _postService = PostService();
  final SharingState sharingState;

  SharingDataBinding({required this.sharingState});

  /// Initialize data and set up streams
  Future<void> initialize() async {
    sharingState.setLoading(true);

    try {
      // Load user data
      final userData = await _postService.loadUserData();
      if (userData != null) {
        // Await setCurrentUser to ensure hidden posts are loaded before posts stream
        await sharingState.setCurrentUser(userData);
      }

      // Set up stream for posts
      if (sharingState.currentUser != null) {
        _setupPostsStream();
      } else {
        sharingState.setLoading(false);
      }
    } catch (e) {
      print("Error initializing data: $e");
      sharingState.setLoading(false);
    }
  }

  /// Set up the stream for posts with avatar loading
  void _setupPostsStream() {
    _postService.getPosts(sharingState.currentUser!.userId).listen(
      (posts) async {
        try {
          await _loadAvatarsForPosts(posts);
          sharingState.setPosts(posts);
        } catch (e) {
          print("Error processing posts: $e");
        } finally {
          sharingState.setLoading(false);
        }
      },
      onError: (error) {
        print("Error in posts stream: $error");
        sharingState.setLoading(false);
      },
    );
  }

  /// Load avatars for all posts
  Future<void> _loadAvatarsForPosts(List<PostModel> posts) async {
    // 1. Collect unique userIds from posts
    final userIds = posts.map((p) => p.userId).toSet().toList();

    // 2. Fetch avatars for all userIds
    final avatarMap = await _postService.fetchAvatarsForUserIds(userIds);

    // 3. Attach avatar to each post
    for (final post in posts) {
      try {
        post.authorAvatar = avatarMap[post.userId];
      } catch (_) {
        // Silently handle if authorAvatar field doesn't exist
      }
    }
  }

  /// Refresh hidden posts from Firestore
  Future<void> refreshHiddenPosts() async {
    if (sharingState.currentUser != null) {
      final hiddenIds = await _postService.getHiddenPosts();
      sharingState.setHiddenPostIds(hiddenIds.toSet());
    }
  }

  /// Create a new post
  Future<void> createPost(PostModel post) async {
    await _postService.createPost(post);
    // The stream will handle updating the UI
  }

  /// Delete a post by ID
  Future<void> deletePost(String postId) async {
    sharingState.setLoading(true);
    try {
      await _postService.deletePost(postId);
      // The stream in initialize should handle updating the state automatically
    } catch (e) {
      print("Error deleting post via service: $e");
    } finally {
      sharingState.setLoading(false);
    }
  }

  /// Update a post's visibility
  Future<void> updatePostVisibility(String postId, bool isPublic) async {
    sharingState.setLoading(true);
    try {
      await _postService.updatePost(postId, {
        'visibility': isPublic ? 'public' : 'private',
      });
      // The stream in initialize should handle updating the state automatically
    } catch (e) {
      print("Error updating post visibility via service: $e");
    } finally {
      sharingState.setLoading(false);
    }
  }

  /// Hide a post for the current user
  Future<void> hidePost(String postId) async {
    await sharingState.hidePost(postId);
  }

  /// Unhide a post for the current user
  Future<void> unhidePost(String postId) async {
    await sharingState.unhidePost(postId);
  }

  /// Extract YouTube video ID from a URL
  String? extractYouTubeVideoId(String url) {
    return _postService.extractYouTubeVideoId(url);
  }

  /// Extract URL from post content
  String? extractUrlFromContent(String content) {
    return _postService.extractUrlFromContent(content);
  }

  /// Set the current music URL in the state
  void setCurrentMusicUrl(String? url) {
    sharingState.setCurrentMusicUrl(url);
  }

  /// Get filtered posts based on user ID and filter settings
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

  /// Get posts formatted for display, with filtering applied
  List<Map<String, dynamic>> getDisplayedPosts({
    required String userId,
    required bool showMyPostsOnly,
    required Set<String> hiddenPostIds,
  }) {
    // Filter and convert PostModel to Map<String, dynamic>
    final filteredPosts = showMyPostsOnly
        ? sharingState.posts.where(
            (post) => post.userId == userId && post.visibility != 'deleted',
          )
        : sharingState.posts.where((post) => post.visibility != 'deleted');

    return filteredPosts
        .where((post) => !hiddenPostIds.contains(post.id))
        .map((post) {
          final map = post.toMap();
          map['id'] = post.id;
          map['authorAvatar'] = post.authorAvatar;
          map['timestamp'] = post.timestamp.toIso8601String();
          return map;
        })
        .toList();
  }
}