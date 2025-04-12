import '../../services/post_service.dart'; // Import the merged service
import '../state/sharing_state.dart';

class SharingDataBinding {
  final PostService _postService = PostService(); // Use the merged service
  final SharingState sharingState;

  SharingDataBinding({required this.sharingState});

  Future<void> initialize() async {
    sharingState.setLoading(true);

    // Load user data
    final userData = await _postService.loadUserData();
    if (userData != null) {
      sharingState.setCurrentUser(userData);
    }

    // Set up stream for posts
    if (sharingState.currentUser != null) {
      _postService
          .getPosts(sharingState.currentUser!.userId)
          .listen((posts) {
        // Convert PostModel to the type expected by SharingState (if needed)
        sharingState.setPosts(posts);
        sharingState.setLoading(false);
      });
    } else {
      sharingState.setLoading(false);
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
      // Optionally, show an error message to the user
    } finally {
      if (sharingState.isLoading) {
        sharingState.setLoading(false);
      }
    }
  }

  Future<void> updatePostVisibility(String postId, bool isPublic) async {
    sharingState.setLoading(true);
    try {
      await _postService.updatePost(postId, {'visibility': isPublic ? 'public' : 'private'});
      // The stream in initialize should handle updating the state automatically
    } catch (e) {
      print("Error updating post visibility via service: $e");
      sharingState.setLoading(false);
      // Optionally, show an error message to the user
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