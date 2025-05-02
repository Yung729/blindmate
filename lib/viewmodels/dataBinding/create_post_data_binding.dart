import '../../models/api/youtube_api.dart';
import '../../models/dataModels/post_model.dart';
import '../../services/gemini_moderation_service.dart';
import '../../services/do_mission_service.dart';
import '../../services/post_service.dart';
import '../../services/trip_journal_service.dart';
import '../state/create_post_state.dart';

class CreatePostDataBinding {
  final CreatePostState createPostState;
  final PostService _postService = PostService();
  final UserTripJournalService _tripJournalService = UserTripJournalService();
  final GeminiModerationService _moderationService = GeminiModerationService();
  final MissionService _missionService = MissionService();

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

  Future<List<Map<String, dynamic>>> fetchUserTripJournals(
    String userId,
  ) async {
    try {
      return await _tripJournalService.fetchUserTripJournals(userId);
    } catch (e) {
      print('Error in data binding - fetchUserTripJournals: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> formatTripJournals(
    List<Map<String, dynamic>> journals,
  ) {
    return _tripJournalService.formatTripJournals(journals);
  }

  /// Now: Stores all trip journals in a single post as a list.
  Future<PostModel?> createPost({
    required String userId,
    required String userName,
    List<Map<String, dynamic>>? tripJournals,
    String? url,
  }) async {
    if (createPostState.postContent.trim().isEmpty &&
        url == null &&
        createPostState.selectedMusicUrl == null &&
        (tripJournals == null || tripJournals.isEmpty)) {
      return null;
    }

    // Determine postType based on content
    PostType postType;
    if (tripJournals != null && tripJournals.isNotEmpty) {
      postType = PostType.tripJournal;
    } else if (createPostState.selectedMusicUrl != null &&
        createPostState.selectedMusicUrl!.isNotEmpty) {
      postType = PostType.musicPost;
    } else if (url != null && url.isNotEmpty) {
      postType = PostType.urlPost;
    } else {
      postType = PostType.normal;
    }

    final newPost = PostModel(
      userId: userId,
      userName: userName,
      content: createPostState.postContent.trim(),
      musicUrl: createPostState.selectedMusicUrl,
      musicTitle: createPostState.selectedMusicTitle,
      timestamp: DateTime.now(),
      visibility: createPostState.isPublic ? 'public' : 'private',
      postType: postType,
      tripJournals: tripJournals,
      url: url,
    );

    await _postService.createPost(newPost);

    await _missionService.trackUserMissionProgress(
      category: 'post',
      type: 'action',
      actionCount: 1,
    );

    return newPost;
  }
}
