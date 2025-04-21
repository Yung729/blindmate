
import 'package:flutter/material.dart';
import '../../models/dataModels/post_model.dart';
import '../UIComponents/post_card.dart';
import '../UIComponents/post_header.dart';
import '../UIComponents/post_content.dart';
import '../UIComponents/post_music_preview.dart';

class MyPostsList extends StatefulWidget {
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
  final void Function(BuildContext context, PostModel post) onViewTripJournal;
  final void Function(List<String> selectedPostIds)? onDeleteSelected;

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
    this.onDeleteSelected,
  }) : super(key: key);

  @override
  State<MyPostsList> createState() => _MyPostsListState();
}

class _MyPostsListState extends State<MyPostsList> {
  final Set<String> _selectedPostIds = {};

  bool get _allSelected =>
      widget.posts.isNotEmpty && _selectedPostIds.length == widget.posts.length;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedPostIds.addAll(widget.posts.map((p) => p.id!));
      } else {
        _selectedPostIds.clear();
      }
    });
  }

  void _toggleSelect(String postId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedPostIds.add(postId);
      } else {
        _selectedPostIds.remove(postId);
      }
    });
  }

  /// Call this from parent after confirmed deletion
  void clearSelection() {
    setState(() {
      _selectedPostIds.clear();
    });
  }

  void _deleteSelected() {
    if (widget.onDeleteSelected != null && _selectedPostIds.isNotEmpty) {
      widget.onDeleteSelected!(_selectedPostIds.toList());
      // Do NOT clear selection here! Only clear after confirmation in parent.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              "You have no posts.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            // Select All Row (checkbox on left, aligned with post checkboxes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                    child: _CustomRoundCheckbox(
                      value: _allSelected,
                      onChanged: (val) => _toggleSelectAll(val),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Select All",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: widget.posts.length + (widget.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < widget.posts.length) {
                    final post = widget.posts[index];
                    final isTripJournal = post.postType == PostType.tripJournal;
                    final isSelected = _selectedPostIds.contains(post.id);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.transparent,
                          width: 2.2,
                        ), // Always transparent border, no outline
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              top: 18.0,
                              right: 4.0,
                            ),
                            child: _CustomRoundCheckbox(
                              value: isSelected,
                              onChanged: (val) => _toggleSelect(post.id!, val),
                            ),
                          ),
                          Expanded(
                            child: PostCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PostHeader(
                                    userName: "You",
                                    avatarAsset: 'assets/default_pic.jpg',
                                    timeAgo: widget.getTimeAgo(post.timestamp),
                                    isPublic: post.isPublic,
                                    onOptions: null, // <-- No 3-dots button
                                    isTripJournal: isTripJournal,
                                    onTripJournalTap: isTripJournal
                                        ? () => widget.onViewTripJournal(
                                              context,
                                              post,
                                            )
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  if (post.content.isNotEmpty)
                                    PostContent(
                                      content: post.content,
                                      isExpanded: widget.expandedPosts
                                          .contains(post.id),
                                      maxLinesCollapsed:
                                          widget.maxLinesCollapsed,
                                      onExpand: () =>
                                          widget.onExpand(post.id!),
                                      onCollapse: () =>
                                          widget.onCollapse(post.id!),
                                    ),
                                  if (post.musicUrl != null)
                                    PostMusicPreview(
                                      musicUrl: post.musicUrl,
                                      musicTitle: post.musicTitle,
                                      onPlay: () => widget.onPlayMusic(post),
                                    ),
                                ],
                              ),
                            ),
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
              ),
            ),
            const SizedBox(height: 60), // Space for the floating delete button
          ],
        ),
        // Floating Delete Button at Bottom
        if (_selectedPostIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: AnimatedScale(
                scale: _selectedPostIds.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: Text(
                    "Delete (${_selectedPostIds.length})",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  onPressed: _deleteSelected,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom round checkbox widget (like Facebook manage posts)
class _CustomRoundCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CustomRoundCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: value ? Colors.red : Colors.white,
          border: Border.all(
            color: value ? Colors.red : Colors.grey.shade400,
            width: 2.2,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: value
            ? const Center(
                child: Icon(Icons.check, color: Colors.white, size: 18),
              )
            : null,
      ),
    );
  }
}