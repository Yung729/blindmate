import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../UIComponents/post_card.dart';
import '../UIComponents/post_header.dart';
import '../UIComponents/post_content.dart';
import '../UIComponents/post_music_preview.dart';
import '../UIComponents/trip_journal_preview.dart';
import '../UIComponents/post_url_preview.dart';
import '../UIComponents/trip_journal_panel.dart';
import '../UIComponents/custom_button.dart';

class MyPostsList extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final String userId;
  final String? avatarUrl;
  final ScrollController scrollController;
  final Set<String> expandedPosts;
  final int maxLinesCollapsed;
  final Function(Map<String, dynamic>) onShowPostOptions;
  final Function(Map<String, dynamic>) onPlayMusic;
  final String Function(DateTime) getTimeAgo;
  final void Function(String postId) onExpand;
  final void Function(String postId) onCollapse;
  final void Function(BuildContext context, Map<String, dynamic> post)
  onViewTripJournal;
  final void Function(List<String> selectedPostIds)? onDeleteSelected;
  final void Function(List<String> selectedPostIds, bool makePublic)?
  onToggleVisibility;
  final bool isMusicPlaying;
  final double musicPlayerHeight;

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
    required this.isMusicPlaying,
    required this.musicPlayerHeight,
  }) : super(key: key);

  @override
  State<MyPostsList> createState() => _MyPostsListState();
}

class _MyPostsListState extends State<MyPostsList> {
  final Set<String> _selectedPostIds = {};
  bool _isDeleting = false;
  bool _showTripJournalsPanel = false;

  bool get _allSelected =>
      widget.posts.isNotEmpty && _selectedPostIds.length == widget.posts.length;

  bool? get _selectedPostsVisibility {
    if (_selectedPostIds.isEmpty) return null;

    final selectedPosts =
        widget.posts
            .where((post) => _selectedPostIds.contains(post['id']))
            .toList();

    final firstVisibility = selectedPosts.first['visibility'] == 'public';
    final allSameVisibility = selectedPosts.every(
      (post) => (post['visibility'] == 'public') == firstVisibility,
    );

    return allSameVisibility ? firstVisibility : null;
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_showTripJournalsPanel) {
      return widget.posts
          .where((post) => post['postType'] == 'tripJournal')
          .toList();
    }
    return widget.posts;
  }

  void _toggleVisibility() {
    final visibility = _selectedPostsVisibility;
    if (visibility != null &&
        widget.onToggleVisibility != null &&
        _selectedPostIds.isNotEmpty) {
      widget.onToggleVisibility!(_selectedPostIds.toList(), !visibility);
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedPostIds.addAll(widget.posts.map((p) => p['id'] as String));
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

      widget.onDeleteSelected!(selectedIds);

      setState(() {
        _selectedPostIds.clear();
        _isDeleting = false;
      });

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

    final tripJournalsCount =
        widget.posts.where((post) => post['postType'] == 'tripJournal').length;

    return Stack(
      children: [
        Column(
          children: [
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
                  const Spacer(),
                  CustomButton(
                    text: 'Trip Journals ($tripJournalsCount)',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext context) {
                          return TripJournalPanel(
                            posts: widget.posts,
                            getTimeAgo: widget.getTimeAgo,
                            onViewTripJournal: widget.onViewTripJournal,
                            onClose: () => Navigator.pop(context),
                          );
                        },
                      );
                    },
                    icon: Icon(
                      _showTripJournalsPanel ? Icons.close : Icons.book,
                      size: 20,
                      color: Colors.white,
                    ),
                    backgroundColor:
                        _showTripJournalsPanel ? Colors.grey : Colors.blue,
                    horizontalPadding: 16,
                    verticalPadding: 8,
                    fontSize: 14,
                    borderRadius: 20,
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
                  final isTripJournal = post['postType'] == 'tripJournal';
                  final isSelected = _selectedPostIds.contains(post['id']);

                  // Parse timestamp safely
                  DateTime postTime;
                  try {
                    postTime = DateTime.parse(post['timestamp']);
                  } catch (_) {
                    postTime = DateTime.now();
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent, width: 2.2),
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
                            onChanged: (val) => _toggleSelect(post['id'], val),
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
                                  timeAgo: widget.getTimeAgo(postTime),
                                  isPublic: post['visibility'] == 'public',
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
                                if ((post['content'] ?? '').isNotEmpty)
                                  PostContent(
                                    content: post['content'],
                                    isExpanded: widget.expandedPosts.contains(
                                      post['id'],
                                    ),
                                    maxLinesCollapsed: widget.maxLinesCollapsed,
                                    onExpand: () => widget.onExpand(post['id']),
                                    onCollapse:
                                        () => widget.onCollapse(post['id']),
                                  ),
                                if (post['url'] != null)
                                  PostUrlPreview(
                                    key: ValueKey('url-preview-${post['id']}'),
                                    linkUrl: post['url'],
                                  ),
                                if (post['musicUrl'] != null)
                                  PostMusicPreview(
                                    musicUrl: post['musicUrl'],
                                    musicTitle: post['musicTitle'],
                                  ),
                                if (isTripJournal &&
                                    (post['tripJournals']?.isNotEmpty ?? false))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: TripJournalPreview(
                                      journals:
                                          List<Map<String, dynamic>>.from(
                                            post['tripJournals'],
                                          ).map((journal) {
                                            final date = journal['date'];
                                            return {
                                              ...journal,
                                              'date':
                                                  date is Timestamp
                                                      ? date.toDate()
                                                      : date,
                                            };
                                          }).toList(),
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
        if (_showTripJournalsPanel)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TripJournalPanel(
                    posts: widget.posts,
                    getTimeAgo: widget.getTimeAgo,
                    onViewTripJournal: widget.onViewTripJournal,
                    onClose:
                        () => setState(() => _showTripJournalsPanel = false),
                  ),
                ),
              ),
            ),
          ),
        if (_selectedPostIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom:
                widget.isMusicPlaying
                    ? (widget.musicPlayerHeight + 24) // 24 for extra margin
                    : 16,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
