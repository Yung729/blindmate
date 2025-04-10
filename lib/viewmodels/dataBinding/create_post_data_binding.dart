import '../../models/api/youtube_api.dart';
import '../../models/dataModels/post_model.dart';
import '../../models/dataModels/user_model.dart';
import '../../services/post_service.dart';
import '../state/create_post_state.dart';

class CreatePostDataBinding {
  final CreatePostState createPostState;
  final PostService _postService = PostService();

  CreatePostDataBinding({required this.createPostState});

  Future<void> searchYouTubeMusic(String query) async {
    if (query.isEmpty) return;

    createPostState.setIsLoading(true);

    List<Map<String, String>> results = await YouTubeAPI.searchYouTubeMusicList(query);

    createPostState.setIsLoading(false);
    createPostState.setMusicResults(results);
  }

  Future<PostModel?> createPost(UserModel user) async {
    if (createPostState.postContent.trim().isEmpty && createPostState.selectedMusicUrl == null) {
      return null;
    }

  final newPost = PostModel(
    userId: user.userId,
    userName: user.name,
    content: createPostState.postContent.trim(),
    musicUrl: createPostState.selectedMusicUrl,
    musicTitle: createPostState.selectedMusicTitle,
    timestamp: DateTime.now(),
    visibility: createPostState.isPublic ? 'public' : 'private',
  );

  // Add the post to Firestore
  await _postService.createPost(newPost);

    return newPost;
  }
}