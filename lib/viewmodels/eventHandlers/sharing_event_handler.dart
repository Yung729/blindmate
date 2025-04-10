import 'package:flutter/material.dart';
import '../../models/dataModels/shared_post_model.dart';
import '../../models/dataModels/user_model.dart';
import '../dataBinding/sharing_data_binding.dart';
import '../state/sharing_state.dart';
import '../../services/sharing_service.dart';
import '../../views/screens/create_post_screen.dart';

class SharingEventHandler {
  final SharingState sharingState;
  final SharingDataBinding dataBinding;
  final SharingService _sharingService = SharingService();

  SharingEventHandler({
    required this.sharingState,
    required this.dataBinding,
  });

  Future<void> init() async {
    await dataBinding.initialize();
  }

  Future<void> navigateToCreatePost(BuildContext context, UserModel user) async {
    final Map<String, dynamic>? newPostData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(user: user),
      ),
    );

    if (newPostData != null) {
      await _sharingService.createPost(
        SharedPostModel(
          id: '', // ID will be assigned by Firestore
          userId: user.userId,
          content: newPostData['content'] ?? '',
          musicUrl: newPostData['musicUrl'],
          visibility: newPostData['visibility'] ?? 'public',
          timestamp: DateTime.now(),
        ),
      );
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
}