
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/state/sharing_state.dart';
import '../../viewmodels/state/music_player_state.dart';
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
import '../UIComponents/floating_youtube_player.dart';
import '../UIComponents/custom_button.dart';
import '../UIComponents/post_music_preview.dart';

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
  SharingScreenState createState() => SharingScreenState();
}

class SharingScreenState extends State<SharingScreen> {
  late SharingEventHandler _eventHandler;
  late SharingState _sharingState;
  bool _showMyPostsOnly = false;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedPosts = <String>{};
  static const int _maxLinesCollapsed = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MusicPlayerState>(context, listen: false).stopMusic();
    });
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

  // Method to refresh posts
  Future<void> _refreshPosts() async {
    // Reset any state if needed
    setState(() {
      _expandedPosts.clear();
    });
    
    // Reinitialize data
    await _eventHandler.init();
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
                    await _eventHandler.deletePost(post['id']);
                    // Auto refresh after deletion
                    _refreshPosts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted')),
                    );
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
                    await _eventHandler.togglePostVisibility(post['id']);
                    // Auto refresh after visibility change
                    _refreshPosts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isPublic 
                              ? 'Post is now private' 
                              : 'Post is now public'
                        ),
                      ),
                    );
                  }
                },
              ),
            if (post['userId'] != widget.userId)
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text("I don't want to see this post"),
                onTap: () async {
                  Navigator.pop(context);
                  await _eventHandler.hidePost(post['id']);
                  // Auto refresh after hiding post
                  _refreshPosts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Post hidden.'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await _eventHandler.unhidePost(post['id']);
                          _refreshPosts();
                        },
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
        final isMusicPlaying = context.watch<MusicPlayerState>().isPlaying;
        const musicPlayerHeight = 80.0;
        final musicPlayerExists =
            context.watch<MusicPlayerState>().currentMusicUrl != null;
        final displayedPosts = _eventHandler.getDisplayedPosts(
          userId: widget.userId,
          showMyPostsOnly: _showMyPostsOnly,
          hiddenPostIds: sharingState.hiddenPostIds,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text("Sharing Space"),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildCreatePostAndToggleRow(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshPosts,
                      child: _showMyPostsOnly
                          ? _buildMyPostsListWithRefresh(
                              displayedPosts,
                              isMusicPlaying,
                              musicPlayerHeight,
                              musicPlayerExists,
                            )
                          : _buildSharedContentList(displayedPosts),
                    ),
                  ),
                ],
              ),
              // Persistent player at the bottom
              Consumer<MusicPlayerState>(
                builder: (context, musicState, _) {
                  if (musicState.currentMusicUrl == null) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: FloatingYoutubePlayer(
                      key: ValueKey(musicState.currentMusicUrl),
                      youtubeUrl: musicState.currentMusicUrl!,
                      title: musicState.currentMusicTitle,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyPostsListWithRefresh(
    List<Map<String, dynamic>> posts,
    bool isMusicPlaying,
    double musicPlayerHeight,
    bool musicPlayerExists,
  ) {
    return MyPostsList(
      posts: posts,
      userId: widget.userId,
      avatarUrl: widget.avatarImg,
      scrollController: _scrollController,
      expandedPosts: _expandedPosts,
      maxLinesCollapsed: _maxLinesCollapsed,
      onShowPostOptions: (post) => _showPostOptions(context, post),
      onPlayMusic: (post) {
        // Use MusicPlayerState to play music globally
        final musicUrl = post['musicUrl'];
        final musicTitle = post['musicTitle'];
        if (musicUrl != null) {
          context.read<MusicPlayerState>().playMusic(
                musicUrl,
                musicTitle,
              );
        }
      },
      getTimeAgo: getTimeAgo,
      onExpand: (postId) {
        setState(() => _expandedPosts.add(postId));
      },
      onCollapse: (postId) {
        setState(() => _expandedPosts.remove(postId));
      },
      onDeleteSelected: _handleDeleteSelected,
      onToggleVisibility: _handleToggleVisibility,
      isMusicPlaying: isMusicPlaying,
      musicPlayerHeight: musicPlayerHeight,
      musicPlayerExists: musicPlayerExists,
    );
  }

  Widget _buildCreatePostAndToggleRow() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Consumer<SharingState>(
            builder: (context, sharingState, _) {
              final avatarUrl = sharingState.currentUser?.avatarImg ?? '';
              return CircleAvatar(
                backgroundImage:
                    avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : const AssetImage('assets/default_pic.jpg')
                            as ImageProvider,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Provider.of<MusicPlayerState>(
                  context,
                  listen: false,
                ).stopMusic();
                final sharingState = Provider.of<SharingState>(
                  context,
                  listen: false,
                );
                final avatarUrl = sharingState.currentUser?.avatarImg ?? '';
                _eventHandler.navigateToCreatePost(
                  context,
                  userId: widget.userId,
                  userName: widget.userName,
                  avatarImg: avatarUrl, // <-- Use latest from state!
                );
              },
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
        // Stop music when toggling between views
        Provider.of<MusicPlayerState>(context, listen: false).stopMusic();

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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No posts available."),
            const SizedBox(height: 16),
            const Text("Pull down to refresh", style: TextStyle(color: Colors.grey)),
            const Icon(Icons.arrow_downward, color: Colors.grey),
          ],
        ),
      );
    }

    // Get music player status to determine padding
    final musicPlayerExists =
        context.watch<MusicPlayerState>().currentMusicUrl != null;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(), // Important for pull-to-refresh
      // Add padding at the bottom when music player exists
      padding: EdgeInsets.only(
        bottom:
            musicPlayerExists
                ? 80.0 + 16.0
                : 16.0, // Music player height + extra padding
      ),
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
          key: ValueKey(post['id']),
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
                              : "Blindmate",
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
                    setState(() => _expandedPosts.add(post['id']));
                  },
                  onCollapse: () {
                    setState(() => _expandedPosts.remove(post['id']));
                  },
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
                    showExploreButton: true,
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
        await _eventHandler.deletePost(id);
      }
      // Auto refresh after batch deletion
      await _refreshPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedIds.length} post(s) deleted')),
      );
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
        await _eventHandler.togglePostVisibility(id);
      }
      // Auto refresh after batch visibility change
      await _refreshPosts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedIds.length} post(s) are now $action')),
      );
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
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          ),
    );
  }
}
