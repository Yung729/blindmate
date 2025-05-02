import 'package:blindmate/services/do_mission_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dataBinding/create_post_data_binding.dart';
import '../state/create_post_state.dart';

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

    String moderationResult = await checkContentModeration(createPostState.postContent);

    // If the content is not deemed unsafe, track user mission progress
    if (moderationResult != 'UNSAFE') {
      // await MissionService.trackUserMissionProgress(
      //   category: 'post',
      //   type: 'action',
      //   actionCount: 1,
      // );
    }

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
