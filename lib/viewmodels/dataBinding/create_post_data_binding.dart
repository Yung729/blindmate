import '../../models/api/youtube_api.dart';
import '../../models/dataModels/post_model.dart';
import '../../models/dataModels/user_model.dart';
import '../../services/gemini_moderation_service.dart';
import '../../services/post_service.dart';
import '../state/create_post_state.dart';

class CreatePostDataBinding {
  final CreatePostState createPostState;
  final PostService _postService = PostService();
  final GeminiModerationService _moderationService = GeminiModerationService();

  CreatePostDataBinding({required this.createPostState});

  Future<String> checkContentModeration(String content) async {
    final result = await _moderationService.checkContentLevel(content);
    return result ?? 'UNSAFE'; // Provide a default value if result is null
  }

  Future<void> searchYouTubeMusic(String query) async {
    if (query.isEmpty) return;

    createPostState.setIsLoading(true);

    List<Map<String, String>> results = await YouTubeAPI.searchYouTubeMusicList(
      query,
    );

    createPostState.setIsLoading(false);
    createPostState.setMusicResults(results);
  }

  /// Now: Stores all trip journals in a single post as a list.
  Future<PostModel?> createPost(
    UserModel user, {
    List<Map<String, dynamic>>? tripJournals,
    String? url,
  }) async {
    if (createPostState.postContent.trim().isEmpty &&
        url == null &&
        createPostState.selectedMusicUrl == null &&
        (tripJournals == null || tripJournals.isEmpty)) {
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
      postType:
          tripJournals != null && tripJournals.isNotEmpty
              ? PostType.tripJournal
              : PostType.normal,
      tripJournals: tripJournals,
      url: url,
    );

    await _postService.createPost(newPost);

    return newPost;
  }
}
