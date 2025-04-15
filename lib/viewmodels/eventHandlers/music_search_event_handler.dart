// lib/viewmodels/eventHandlers/music_search_event_handler.dart
import '../state/create_post_state.dart';
import '../../models/api/youtube_api.dart'; // Import your YouTube API service

class MusicSearchEventHandler {
  final CreatePostState createPostState;

  MusicSearchEventHandler({required this.createPostState});

  Future<void> handleMusicSearch(String query) async {
    if (query.trim().isEmpty) {
      createPostState.clearMusicResults();
      return;
    }

    createPostState.setIsLoading(true);

    try {
      // Call the actual YouTube API service
      final results = await YouTubeAPI.searchYouTubeMusicList(query);
      
      if (results.isNotEmpty) {
        createPostState.setMusicResults(results);
      } else {
        // No results found
        createPostState.clearMusicResults();
      }
    } catch (e) {
      print("Error searching music: $e");
      // Handle error
      createPostState.clearMusicResults();
    } finally {
      createPostState.setIsLoading(false);
    }
  }
}