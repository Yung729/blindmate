import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/state/sharing_state.dart';
import '../../viewmodels/dataBinding/sharing_data_binding.dart';
import '../../viewmodels/eventHandlers/sharing_event_handler.dart';
import '../UIComponents/post_card.dart';
import '../UIComponents/post_header.dart';
import '../UIComponents/post_content.dart';
import 'my_posts_list.dart';
import '../UIComponents/custom_dialog.dart';
import '../UIComponents/trip_journal_card.dart';
import '../UIComponents/post_url_preview.dart';
import '../UIComponents/trip_journal_preview.dart';
import '../UIComponents/inline_youtube_player.dart';
import '../UIComponents/custom_button.dart';

class SharingScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String avatarImg;

  const SharingScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.avatarImg,
  });

  @override
  _SharingScreenState createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  late SharingEventHandler _eventHandler;
  late SharingState _sharingState;
  bool _showMyPostsOnly = false;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedPosts = <String>{};
  static const int _maxLinesCollapsed = 3;

  @override
  void initState() {
    super.initState();
    _sharingState = context.read<SharingState>();
    final dataBinding = SharingDataBinding(sharingState: _sharingState);

    _eventHandler = SharingEventHandler(
      sharingState: _sharingState,
      dataBinding: dataBinding,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eventHandler.init();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String getTimeAgo(DateTime postTime) {
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    return '${postTime.day}/${postTime.month}/${postTime.year}';
  }

  void _showPostOptions(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        final bool isPublic = post['visibility'] == 'public';
        return Wrap(
          children: <Widget>[
            if (post['userId'] == widget.userId)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Post'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmDelete = await showConfirmDialog(
                    context,
                    'Delete Post',
                    'Are you sure you want to delete this post?',
                  );
                  if (confirmDelete) {
                    _eventHandler.deletePost(post['id']);
                  }
                },
              ),
            if (post['userId'] == widget.userId)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: Text(isPublic ? 'Make Private' : 'Make Public'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmVisibility = await showConfirmDialog(
                    context,
                    isPublic ? 'Make Private' : 'Make Public',
                    isPublic
                        ? 'Are you sure you want to make this post private?'
                        : 'Are you sure you want to make this post public?',
                  );
                  if (confirmVisibility) {
                    _eventHandler.togglePostVisibility(post['id']);
                  }
                },
              ),
            if (post['userId'] != widget.userId)
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text("I don't want to see this post"),
                onTap: () {
                  Navigator.pop(context);
                  _eventHandler.hidePost(post['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Post hidden.'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => _eventHandler.unhidePost(post['id']),
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharingState>(
      builder: (context, sharingState, child) {
        final displayedPosts = _eventHandler.getDisplayedPosts(
          userId: widget.userId,
          showMyPostsOnly: _showMyPostsOnly,
          hiddenPostIds: sharingState.hiddenPostIds,
        );

        return Scaffold(
          appBar: AppBar(title: const Text("Sharing Space")),
          body: Column(
            children: [
              _buildCreatePostAndToggleRow(),
              Expanded(
                child:
                    _showMyPostsOnly
                        ? MyPostsList(
                          posts: displayedPosts,
                          userId: widget.userId,
                          avatarUrl: widget.avatarImg,
                          scrollController: _scrollController,
                          expandedPosts: _expandedPosts,
                          maxLinesCollapsed: _maxLinesCollapsed,
                          onShowPostOptions:
                              (post) => _showPostOptions(context, post),
                          onPlayMusic:
                              (post) =>
                                  _eventHandler.playMusic(post['musicUrl']),
                          getTimeAgo: getTimeAgo,
                          onExpand: (postId) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() => _expandedPosts.add(postId));
                            });
                          },
                          onCollapse: (postId) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() => _expandedPosts.remove(postId));
                            });
                          },
                          onViewTripJournal: _showTripJournalDialog,
                          onDeleteSelected: _handleDeleteSelected,
                          onToggleVisibility: _handleToggleVisibility,
                        )
                        : _buildSharedContentList(displayedPosts),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreatePostAndToggleRow() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage:
                widget.avatarImg.isNotEmpty
                    ? NetworkImage(widget.avatarImg)
                    : const AssetImage('assets/default_pic.jpg')
                        as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap:
                  () => _eventHandler.navigateToCreatePost(
                    context,
                    userId: widget.userId,
                    userName: widget.userName,
                    avatarImg: widget.avatarImg,
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "What's on your mind?",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildSingleToggleButton(),
        ],
      ),
    );
  }

  Widget _buildSingleToggleButton() {
    final bool isAllPosts = !_showMyPostsOnly;
    return CustomButton(
      text: isAllPosts ? "All Posts" : "My Posts",
      onPressed: () {
        setState(() {
          _showMyPostsOnly = !_showMyPostsOnly;
          _scrollController.jumpTo(0);
          _expandedPosts.clear();
        });
      },
      icon: Icon(
        isAllPosts ? Icons.public : Icons.person,
        color: Colors.white,
        size: 20,
      ),
      backgroundColor: isAllPosts ? Colors.blue : Colors.grey[400],
      horizontalPadding: 18,
      verticalPadding: 10,
      fontSize: 14,
      borderRadius: 24,
    );
  }

  Widget _buildSharedContentList(List<Map<String, dynamic>> posts) {
    if (_sharingState.isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty && !_sharingState.isLoading) {
      return const Center(child: Text("No posts available."));
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isTripJournal = post['postType'] == 'tripJournal';
        final avatarUrl = post['authorAvatar'];
        final isPublic = post['visibility'] == 'public';

        // Parse timestamp safely
        DateTime postTime;
        try {
          postTime = DateTime.parse(post['timestamp']);
        } catch (_) {
          postTime = DateTime.now();
        }

        return PostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PostHeader(
                      userName:
                          post['userId'] == widget.userId
                              ? "You"
                              : "Depression People",
                      avatarUrl: avatarUrl,
                      timeAgo: getTimeAgo(postTime),
                      isPublic: isPublic,
                      onOptions: () => _showPostOptions(context, post),
                      isTripJournal: isTripJournal,
                      onTripJournalTap:
                          isTripJournal
                              ? () => _showTripJournalDialog(context, post)
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (post['content']?.isNotEmpty ?? false)
                PostContent(
                  content: post['content'],
                  isExpanded: _expandedPosts.contains(post['id']),
                  maxLinesCollapsed: _maxLinesCollapsed,
                  onExpand: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _expandedPosts.add(post['id']));
                    });
                  },
                  onCollapse: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _expandedPosts.remove(post['id']));
                    });
                  },
                ),
              if (post['url'] != null)
                PostUrlPreview(
                  key: ValueKey('url-preview-${post['id']}'),
                  linkUrl: post['url'],
                ),
              if (post['musicUrl'] != null)
                InlineYoutubePlayer(
                  youtubeUrl: post['musicUrl'],
                  title: post['musicTitle'],
                ),
              if (isTripJournal && (post['tripJournals']?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TripJournalPreview(
                    journals:
                        List<Map<String, dynamic>>.from(
                          post['tripJournals'] ?? [],
                        ).map((journal) {
                          final date = journal['date'];
                          return {
                            ...journal,
                            'date': date is Timestamp ? date.toDate() : date,
                          };
                        }).toList(),
                    onTap: () => _showTripJournalDialog(context, post),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteSelected(List<String> selectedIds) async {
    final confirm = await showConfirmDialog(
      context,
      'Delete Posts',
      'Are you sure you want to delete ${selectedIds.length} post(s)?',
    );
    if (confirm) {
      for (final id in selectedIds) {
        _eventHandler.deletePost(id);
      }
    }
  }

  Future<void> _handleToggleVisibility(
    List<String> selectedIds,
    bool makePublic,
  ) async {
    final action = makePublic ? 'public' : 'private';
    final confirm = await showConfirmDialog(
      context,
      'Change Visibility',
      'Are you sure you want to make ${selectedIds.length} post(s) $action?',
    );
    if (confirm) {
      for (final id in selectedIds) {
        _eventHandler.togglePostVisibility(id);
      }
    }
  }

  void _showTripJournalDialog(BuildContext context, Map<String, dynamic> post) {
    final journals = List<Map<String, dynamic>>.from(
      post['tripJournals'] ?? [],
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder:
          (context) => Center(
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
              ),
            ),
          ),
    );
  }
}
