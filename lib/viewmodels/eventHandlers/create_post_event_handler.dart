import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dataBinding/create_post_data_binding.dart';
import '../state/create_post_state.dart';
import '../state/do_mission_state.dart';

class CreatePostEventHandler {
  final CreatePostState createPostState;
  final CreatePostDataBinding dataBinding;
  final String userId;
  final String userName;
  final String userAvatar;

  CreatePostEventHandler({
    required this.createPostState,
    required this.dataBinding,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  // Alternative constructor that creates the data binding
  factory CreatePostEventHandler.withMissionState({
    required CreatePostState createPostState,
    required MissionState missionState,
    required String userId,
    required String userName,
    required String userAvatar,
  }) {
    return CreatePostEventHandler(
      createPostState: createPostState,
      dataBinding: CreatePostDataBinding(
        createPostState: createPostState,
        missionState: missionState,
      ),
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
    );
  }

  // Draft management methods
  Future<bool> hasDraft() async {
    return await dataBinding.hasDraft();
  }

  Future<void> loadDraft() async {
    await dataBinding.loadDraft();
  }

  Future<void> saveToDraft() async {
    await dataBinding.saveToDraft(userId);
  }

  Future<void> clearDraft() async {
    await dataBinding.clearDraft();
  }

  Future<List<Map<String, dynamic>>> loadUserTripJournals() async {
    try {
      final journals = await dataBinding.fetchUserTripJournals(userId);
      return journals;
    } catch (e) {
      print('Error in event handler - loadUserTripJournals: $e');
      return [];
    }
  }

  void selectTripJournal(List<Map<String, dynamic>> selectedJournals) {
    createPostState.setTripJournals(selectedJournals);
  }

  // Clear selected trip journals
  void clearTripJournals() {
    createPostState.clearTripJournals();
  }

  Future<String> checkContentModeration(String content) async {
    return await dataBinding.checkContentModeration(content);
  }

  Future<void> handleMusicSearch(String query) async {
    await dataBinding.searchYouTubeMusic(query);
  }

  void selectMusic(String? url, String? title) {
    if (url != null && title != null) {
      createPostState.selectMusic(url, title);
    } else {
      createPostState.clearMusicSelection();
    }
  }

  void toggleVisibility(bool isPublic) {
    createPostState.setIsPublic(isPublic);
  }

  void updatePostContent(String content) {
    createPostState.setPostContent(content);
  }

  /// Updated: Accepts a list of trip journals and passes it to dataBinding.createPost
  Future<void> sharePost({List<Map<String, dynamic>>? tripJournals}) async {
    await dataBinding.createPost(
      userId: userId,
      userName: userName,
      tripJournals: tripJournals,
      url: createPostState.selectedLinkUrl,
    );

    createPostState.reset();
  }

  void shareMusic() {
    if (createPostState.selectedMusicUrl != null) {
      Share.share("Check out this song: ${createPostState.selectedMusicUrl}");
    }
  }

  Future<void> launchMusicURL(BuildContext context) async {
    if (createPostState.selectedMusicUrl != null) {
      final Uri url = Uri.parse(createPostState.selectedMusicUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open the link.")),
          );
        }
      }
    }
  }
}
