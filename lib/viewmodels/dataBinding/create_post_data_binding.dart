import '../../models/api/youtube_api.dart';
import '../../models/dataModels/post_model.dart';
import '../../services/gemini_moderation_service.dart';
import '../../services/do_mission_service.dart';
import '../../services/post_service.dart';
import '../../services/trip_journal_service.dart';
import '../../services/draft_post_service.dart';
import '../state/create_post_state.dart';
import 'package:blindmate/viewmodels/eventHandlers/mission_event_handler.dart';
import 'package:blindmate/viewmodels/state/do_mission_state.dart';

class CreatePostDataBinding {
  final CreatePostState createPostState;
  final PostService _postService = PostService();
  final UserTripJournalService _tripJournalService = UserTripJournalService();
  final GeminiModerationService _moderationService = GeminiModerationService();
  final MissionService _missionService = MissionService();
  final DraftPostService _draftService = DraftPostService();
  late MissionEventHandler? _missionEventHandler;

  CreatePostDataBinding({
    required CreatePostState createPostState,
    MissionState? missionState,
  }) : createPostState = createPostState {
    if (missionState != null) {
      _missionEventHandler = MissionEventHandler(missionState: missionState);
    }
  }

  // Check if a draft exists
  Future<bool> hasDraft() async {
    return await _draftService.hasDraft();
  }

  // Load draft content
  Future<void> loadDraft() async {
    final draft = await _draftService.getDraft();
    if (draft != null) {
      createPostState.loadFromDraft(
        content: draft['content'] ?? '',
        isPublicValue: draft['isPublic'] ?? true,
        musicUrl: draft['musicUrl'],
        musicTitle: draft['musicTitle'],
        linkUrl: draft['linkUrl'],
        tripJournals: draft['tripJournals'] as List<Map<String, dynamic>>?,
      );
    }
  }

  // Save the current post as a draft
  Future<void> saveToDraft(String userId) async {
    await _draftService.saveDraft(
      userId: userId,
      content: createPostState.postContent,
      isPublic: createPostState.isPublic,
      musicUrl: createPostState.selectedMusicUrl,
      musicTitle: createPostState.selectedMusicTitle,
      linkUrl: createPostState.selectedLinkUrl,
      tripJournals: createPostState.tripJournals,
    );
    createPostState.resetUnsavedChanges();
  }

  // Clear the draft
  Future<void> clearDraft() async {
    await _draftService.clearDraft();
  }

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

    // Clear the draft after successfully posting
    await _draftService.clearDraft();

    if (_missionEventHandler != null) {
      // Track mission progress based on post type
      if (postType == PostType.musicPost) {
        await _missionEventHandler?.trackMissionProgress(
          category: 'post',
          type: 'action',
          actionCount: 1,
          actionType: 'musicpost',
        );
      } else if (postType == PostType.tripJournal) {
        await _missionEventHandler?.trackMissionProgress(
          category: 'post',
          type: 'action',
          actionCount: 1,
          actionType: 'tripjournal',
        );
      } else {
        await _missionEventHandler?.trackMissionProgress(
          category: 'post',
          type: 'action',
          actionCount: 1,
          actionType: 'post',
        );
      }
    }

    return newPost;
  }
}
