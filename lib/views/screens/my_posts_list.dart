import 'package:flutter/material.dart';
import '../../models/dataModels/post_model.dart';
import '../UIComponents/post_card.dart';
import '../UIComponents/post_header.dart';
import '../UIComponents/post_content.dart';
import '../UIComponents/post_music_preview.dart';
import '../UIComponents/trip_journal_preview.dart';
import '../UIComponents/post_url_preview.dart';

class MyPostsList extends StatefulWidget {
  final List<PostModel> posts;
  final String userId;
  final String? avatarUrl;
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
  final void Function(List<String> selectedPostIds, bool makePublic)?
  onToggleVisibility;

  const MyPostsList({
    Key? key,
    required this.posts,
    required this.userId,
    required this.avatarUrl,
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
    this.onToggleVisibility,
  }) : super(key: key);

  @override
  State<MyPostsList> createState() => _MyPostsListState();
}

class _MyPostsListState extends State<MyPostsList> {
  final Set<String> _selectedPostIds = {};
  bool _isDeleting = false;

  bool get _allSelected =>
      widget.posts.isNotEmpty && _selectedPostIds.length == widget.posts.length;

  bool? get _selectedPostsVisibility {
    if (_selectedPostIds.isEmpty) return null;

    final selectedPosts =
        widget.posts
            .where((post) => _selectedPostIds.contains(post.id))
            .toList();

    final firstVisibility = selectedPosts.first.isPublic;
    final allSameVisibility = selectedPosts.every(
      (post) => post.isPublic == firstVisibility,
    );

    return allSameVisibility ? firstVisibility : null;
  }

  void _toggleVisibility() {
    final visibility = _selectedPostsVisibility;
    if (visibility != null &&
        widget.onToggleVisibility != null &&
        _selectedPostIds.isNotEmpty) {
      // Pass the opposite of current visibility to toggle
      widget.onToggleVisibility!(_selectedPostIds.toList(), !visibility);
    }
  }

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
    if (widget.onDeleteSelected != null &&
        _selectedPostIds.isNotEmpty &&
        !_isDeleting) {
      final selectedIds = List<String>.from(_selectedPostIds);

      setState(() {
        _isDeleting = true;
      });

      // Call delete callback
      widget.onDeleteSelected!(selectedIds);

      // Force UI refresh after deletion
      setState(() {
        _selectedPostIds.clear();
        _isDeleting = false;
      });

      // Force another refresh to ensure list updates
      Future.microtask(() {
        if (mounted) setState(() {});
      });
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
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: widget.posts.length,
                itemBuilder: (context, index) {
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
                      boxShadow:
                          isSelected
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
                                  avatarUrl: widget.avatarUrl,
                                  timeAgo: widget.getTimeAgo(post.timestamp),
                                  isPublic: post.isPublic,
                                  onOptions: null,
                                  isTripJournal: isTripJournal,
                                  onTripJournalTap:
                                      isTripJournal
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
                                    isExpanded: widget.expandedPosts.contains(
                                      post.id,
                                    ),
                                    maxLinesCollapsed: widget.maxLinesCollapsed,
                                    onExpand: () => widget.onExpand(post.id!),
                                    onCollapse:
                                        () => widget.onCollapse(post.id!),
                                  ),
                                if (post.url != null)
                                  PostUrlPreview(
                                    key: ValueKey('url-preview-${post.id}'),
                                    linkUrl: post.url!,
                                  ),
                                if (post.musicUrl != null)
                                  PostMusicPreview(
                                    musicUrl: post.musicUrl,
                                    musicTitle: post.musicTitle,
                                    onPlay: () => widget.onPlayMusic(post),
                                  ),
                                if (isTripJournal &&
                                    (post.tripJournals?.isNotEmpty ?? false))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: TripJournalPreview(
                                      journals: post.tripJournals!,
                                      onTap:
                                          () => widget.onViewTripJournal(
                                            context,
                                            post,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Floating Delete Button at Bottom
        if (_selectedPostIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Delete button
                  AnimatedScale(
                    scale: _selectedPostIds.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      icon:
                          _isDeleting
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        _isDeleting
                            ? "Deleting..."
                            : "Delete (${_selectedPostIds.length})",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      onPressed: _isDeleting ? null : _deleteSelected,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Visibility toggle button
                  AnimatedScale(
                    scale: _selectedPostIds.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _selectedPostsVisibility == null
                            ? Icons.block
                            : (_selectedPostsVisibility!
                                ? Icons.visibility_off
                                : Icons.visibility),
                        color: Colors.white,
                      ),
                      label: Text(
                        _selectedPostsVisibility == null
                            ? "Mixed Visibility"
                            : (_selectedPostsVisibility!
                                ? "Make Private (${_selectedPostIds.length})"
                                : "Make Public (${_selectedPostIds.length})"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedPostsVisibility == null
                                ? Colors.grey
                                : Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      onPressed:
                          _selectedPostsVisibility == null
                              ? null
                              : _toggleVisibility,
                    ),
                  ),
                ],
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
          boxShadow:
              value
                  ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child:
            value
                ? const Center(
                  child: Icon(Icons.check, color: Colors.white, size: 18),
                )
                : null,
      ),
    );
  }
}
