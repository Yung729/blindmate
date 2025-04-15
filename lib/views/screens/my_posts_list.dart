
import 'package:flutter/material.dart';
import '../../models/dataModels/post_model.dart';
import '../UIComponents/post_card.dart';
import '../UIComponents/post_header.dart';
import '../UIComponents/post_content.dart';
import '../UIComponents/post_music_preview.dart';

class MyPostsList extends StatelessWidget {
  final List<PostModel> posts;
  final String userId;
  final int loadedPostCount;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final Set<String> expandedPosts;
  final int maxLinesCollapsed;
  final Function(PostModel) onShowPostOptions;
  final Function(PostModel) onPlayMusic;
  final String Function(DateTime) getTimeAgo;
  final void Function(String postId) onExpand;
  final void Function(String postId) onCollapse;
  final void Function(BuildContext context, PostModel post) onViewTripJournal; // NEW

  const MyPostsList({
    Key? key,
    required this.posts,
    required this.userId,
    required this.loadedPostCount,
    required this.isLoadingMore,
    required this.scrollController,
    required this.expandedPosts,
    required this.maxLinesCollapsed,
    required this.onShowPostOptions,
    required this.onPlayMusic,
    required this.getTimeAgo,
    required this.onExpand,
    required this.onCollapse,
    required this.onViewTripJournal, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text("You have no posts."));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: posts.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < posts.length) {
          final post = posts[index];
          final isTripJournal = post.postType == PostType.tripJournal;

          return PostCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostHeader(
                  userName: "You",
                  avatarAsset: 'assets/default_pic.jpg',
                  timeAgo: getTimeAgo(post.timestamp),
                  isPublic: post.isPublic,
                  onOptions: () => onShowPostOptions(post),
                  isTripJournal: isTripJournal,
                  onTripJournalTap: isTripJournal
                      ? () => onViewTripJournal(context, post)
                      : null,
                ),
                const SizedBox(height: 8),
                if (post.content.isNotEmpty)
                  PostContent(
                    content: post.content,
                    isExpanded: expandedPosts.contains(post.id),
                    maxLinesCollapsed: maxLinesCollapsed,
                    onExpand: () => onExpand(post.id!),
                    onCollapse: () => onCollapse(post.id!),
                  ),
                if (post.musicUrl != null)
                  PostMusicPreview(
                    musicUrl: post.musicUrl,
                    musicTitle: post.musicTitle,
                    onPlay: () => onPlayMusic(post),
                  ),
              ],
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
