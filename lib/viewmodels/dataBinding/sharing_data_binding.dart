import '../../services/sharing_service.dart';
import '../../models/dataModels/shared_post_model.dart';
import '../state/sharing_state.dart';

class SharingDataBinding {
  final SharingService _sharingService = SharingService();
  final SharingState sharingState;

  SharingDataBinding({required this.sharingState});

  Future<void> initialize() async {
    sharingState.setLoading(true);
    
    // Load user data
    final userData = await _sharingService.loadUserData();
    if (userData != null) {
      sharingState.setCurrentUser(userData);
    }
    
    // Set up stream for posts
    if (sharingState.currentUser != null) {
      _sharingService
          .getSharedPosts(sharingState.currentUser!.userId)
          .listen((posts) {
        sharingState.setPosts(posts);
        sharingState.setLoading(false);
      });
    } else {
      sharingState.setLoading(false);
    }
  }

  String? extractYouTubeVideoId(String url) {
    return _sharingService.extractYouTubeVideoId(url);
  }

  String? extractUrlFromContent(String content) {
    return _sharingService.extractUrlFromContent(content);
  }

  void setCurrentMusicUrl(String? url) {
    sharingState.setCurrentMusicUrl(url);
  }
}