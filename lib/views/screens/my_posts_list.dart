import 'package:flutter/material.dart';
import '../UIComponents/post_card.dart';
import '../UIComponents/post_header.dart';
import '../UIComponents/post_content.dart';
import '../UIComponents/post_music_preview.dart';
import '../UIComponents/post_url_preview.dart';
import '../UIComponents/custom_button.dart';
import '../UIComponents/trip_journal_preview.dart'; // Add this import
import '../UIComponents/trip_journal_card.dart'; // Add this import

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
  final void Function(List<String> selectedPostIds)? onDeleteSelected;
  final void Function(List<String> selectedPostIds, bool makePublic)?
  onToggleVisibility;
  final bool isMusicPlaying;
  final double musicPlayerHeight;
  final bool musicPlayerExists;

  const MyPostsList({
    super.key,
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
    this.onDeleteSelected,
    this.onToggleVisibility,
    required this.isMusicPlaying,
    required this.musicPlayerHeight,
    required this.musicPlayerExists,
  });

  @override
  State<MyPostsList> createState() => _MyPostsListState();
}

class _MyPostsListState extends State<MyPostsList> {
  final Set<String> _selectedPostIds = {};
  bool _isDeleting = false;
  String _activeFilter =
      'all'; // 'all', 'public', 'private', 'music', 'url', 'textOnly', 'tripJournal'
  
  // Track which trip journals are expanded in full card view
  final Set<String> _expandedTripJournals = {};

  bool get _allSelected =>
      _filteredPosts.isNotEmpty &&
      _selectedPostIds.length == _filteredPosts.length;

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
    // First apply visibility filters
    List<Map<String, dynamic>> visibilityFiltered;
    if (_activeFilter == 'public') {
      visibilityFiltered =
          widget.posts.where((post) => post['visibility'] == 'public').toList();
    } else if (_activeFilter == 'private') {
      visibilityFiltered =
          widget.posts.where((post) => post['visibility'] != 'public').toList();
    } else {
      visibilityFiltered = widget.posts;
    }

    // Then apply content type filters
    if (_activeFilter == 'music') {
      return visibilityFiltered
          .where((post) => post['musicUrl'] != null)
          .toList();
    } else if (_activeFilter == 'url') {
      return visibilityFiltered.where((post) => post['url'] != null).toList();
    } else if (_activeFilter == 'textOnly') {
      return visibilityFiltered
          .where(
            (post) =>
                (post['content']?.isNotEmpty ?? false) &&
                post['musicUrl'] == null &&
                post['url'] == null,
          )
          .toList();
    } else if (_activeFilter == 'tripJournal') {
      // Add trip journal filter
      return visibilityFiltered
          .where((post) => post['tripJournals'] != null && 
                          (post['tripJournals'] as List?)?.isNotEmpty == true)
          .toList();
    } else if (_activeFilter == 'all' ||
        _activeFilter == 'public' ||
        _activeFilter == 'private') {
      return visibilityFiltered;
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
        _selectedPostIds.addAll(_filteredPosts.map((p) => p['id'] as String));
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

  // Toggle trip journal expansion
  void _toggleTripJournalExpansion(String postId) {
    setState(() {
      if (_expandedTripJournals.contains(postId)) {
        _expandedTripJournals.remove(postId);
      } else {
        _expandedTripJournals.add(postId);
      }
    });
  }

  // Show trip journal in a dialog
  void _showTripJournalDialog(BuildContext context, Map<String, dynamic> post) {
    final journals = List<Map<String, dynamic>>.from(
      post['tripJournals'] ?? [],
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.60,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TripJournalBookCard(
            journals: journals,
            padding: const EdgeInsets.all(0),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle at the top
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Filter Posts",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Done",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Text(
                          "By Visibility",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      _buildFilterOption('All Posts', 'all', setModalState),
                      _buildFilterOption(
                        'Public Posts',
                        'public',
                        setModalState,
                      ),
                      _buildFilterOption(
                        'Private Posts',
                        'private',
                        setModalState,
                      ),

                      const Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 4.0),
                        child: Text(
                          "By Content Type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      _buildFilterOption('Music Posts', 'music', setModalState),
                      _buildFilterOption('URL Posts', 'url', setModalState),
                      _buildFilterOption(
                        'Text Only Posts',
                        'textOnly',
                        setModalState,
                      ),
                      // Add Trip Journal filter option
                      _buildFilterOption(
                        'Trip Journals',
                        'tripJournal',
                        setModalState,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
    String title,
    String filterValue,
    StateSetter setModalState,
  ) {
    return InkWell(
      onTap: () {
        // Update both the modal state and the widget state
        setModalState(() {
          _activeFilter = filterValue;
        });
        setState(() {
          _activeFilter = filterValue;
          _selectedPostIds.clear(); // Clear selection when filter changes
        });
        // No longer closing the modal after selection
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              _activeFilter == filterValue
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _activeFilter == filterValue ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    _activeFilter == filterValue
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    _activeFilter == filterValue ? Colors.blue : Colors.black,
              ),
            ),
            if (filterValue == 'public' || filterValue == 'private')
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  filterValue == 'public'
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            if (filterValue == 'music')
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.music_note, size: 16, color: Colors.grey),
              ),
            if (filterValue == 'url')
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.link, size: 16, color: Colors.grey),
              ),
            if (filterValue == 'textOnly')
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.text_fields, size: 16, color: Colors.grey),
              ),
            // Add Trip Journal icon
            if (filterValue == 'tripJournal')
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.travel_explore, size: 16, color: Colors.grey),
              ),
            if (_activeFilter == filterValue)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getFilterCount(filterValue),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFilterCount(String filterValue) {
    int count = 0;

    // Calculate count based on filter type
    if (filterValue == 'all') {
      count = widget.posts.length;
    } else if (filterValue == 'public') {
      count =
          widget.posts.where((post) => post['visibility'] == 'public').length;
    } else if (filterValue == 'private') {
      count =
          widget.posts.where((post) => post['visibility'] != 'public').length;
    } else if (filterValue == 'music') {
      count = widget.posts.where((post) => post['musicUrl'] != null).length;
    } else if (filterValue == 'url') {
      count = widget.posts.where((post) => post['url'] != null).length;
    } else if (filterValue == 'textOnly') {
      count =
          widget.posts
              .where(
                (post) =>
                    (post['content']?.isNotEmpty ?? false) &&
                    post['musicUrl'] == null &&
                    post['url'] == null,
              )
              .length;
    } else if (filterValue == 'tripJournal') {
      // Count trip journal posts
      count = widget.posts.where((post) => 
        post['tripJournals'] != null && 
        (post['tripJournals'] as List?)?.isNotEmpty == true
      ).length;
    }

    return count.toString();
  }

  // Top bar with Select All and Filter button
  Widget _buildTopBar() {
    return Padding(
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
            text: 'Filter',
            onPressed: _showFilterOptions,
            icon: Icon(Icons.filter_list, size: 20, color: Colors.white),
            backgroundColor:
                _activeFilter != 'all' ? Colors.blue.shade700 : Colors.blue,
            horizontalPadding: 16,
            verticalPadding: 8,
            fontSize: 14,
            borderRadius: 20,
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'all';
      case 'public':
        return 'public';
      case 'private':
        return 'private';
      case 'music':
        return 'music';
      case 'url':
        return 'URL';
      case 'textOnly':
        return 'text-only';
      case 'tripJournal':
        return 'trip journal';
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;

    if (posts.isEmpty) {
      return Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    _activeFilter == 'all'
                        ? "You have no posts."
                        : "No ${_getFilterDisplayName(_activeFilter)} posts found.",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                // Add padding at the bottom when music player exists
                padding: EdgeInsets.only(
                  bottom:
                      widget.musicPlayerExists
                          ? widget.musicPlayerHeight + 16.0
                          : 16.0,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final isSelected = _selectedPostIds.contains(post['id']);
                  
                  // Check if post has trip journals
                  final hasTripJournals = post['tripJournals'] != null && 
                                         (post['tripJournals'] as List?)?.isNotEmpty == true;
                  final isTripJournalExpanded = _expandedTripJournals.contains(post['id']);

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
                                  onOptions: () => widget.onShowPostOptions(post),
                                  isTripJournal: hasTripJournals,
                                  onTripJournalTap: hasTripJournals 
                                      ? () => _showTripJournalDialog(context, post)
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
                                
                                // Add Trip Journal Preview or Card
                                if (hasTripJournals) ...[
                                  const SizedBox(height: 12),
                                  if (isTripJournalExpanded)
                                    // Show full trip journal card when expanded
                                    TripJournalBookCard(
                                      journals: List<Map<String, dynamic>>.from(post['tripJournals']),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      onClose: () => _toggleTripJournalExpansion(post['id']),
                                    )
                                  else
                                    // Show trip journal preview when collapsed
                                    TripJournalPreview(
                                      journals: List<Map<String, dynamic>>.from(post['tripJournals']),
                                      onTap: () => _toggleTripJournalExpansion(post['id']),
                                    ),
                                ],
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
        if (_selectedPostIds.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom:
                widget.musicPlayerExists
                    ? widget.musicPlayerHeight +
                        25 // Position above music player with padding
                    : 18, // Position at bottom with padding when no music player
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

  const _CustomRoundCheckbox({required this.value, required this.onChanged});

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