import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/dataModels/post_model.dart';
import '../../models/dataModels/user_model.dart';
import '../dataBinding/create_post_data_binding.dart';
import '../state/create_post_state.dart';

class CreatePostEventHandler {
  final CreatePostState createPostState;
  final CreatePostDataBinding dataBinding;
  final UserModel user;

  CreatePostEventHandler({
    required this.createPostState,
    required this.dataBinding,
    required this.user,
  });

  Future<void> handleMusicSearch(String query) async {
    await dataBinding.searchYouTubeMusic(query);
  }

void selectMusic(String? url, String? title) {
  createPostState.selectedMusicUrl = url;
  createPostState.selectedMusicTitle = title;
}

  void toggleVisibility(bool isPublic) {
    createPostState.setIsPublic(isPublic);
  }

  void updatePostContent(String content) {
    createPostState.setPostContent(content);
  }

  Future<void> sharePost() async {
    await dataBinding.createPost(user);
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
