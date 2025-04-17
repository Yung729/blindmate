import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/user_model.dart';
import '../../viewmodels/state/sharing_state.dart';
import '../../viewmodels/dataBinding/sharing_data_binding.dart';
import '../../viewmodels/eventHandlers/sharing_event_handler.dart';
import '../UIComponents/floating_music_player.dart';
import '../UIComponents/custom_button.dart';
import '../../models/dataModels/post_model.dart';
import '../UIComponents/post_privacy_indicator.dart';
import '../UIComponents/post_card.dart';
import '../UIComponents/post_header.dart';
import '../UIComponents/post_content.dart';
import '../UIComponents/post_music_preview.dart';
import 'my_posts_list.dart';
import '../UIComponents/custom_dialog.dart'; // Import the dialog_utils

class SharingScreen extends StatefulWidget {
  final UserModel user;

  const SharingScreen({super.key, required this.user});

  @override
  _SharingScreenState createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  late SharingEventHandler _eventHandler;
  late SharingState _sharingState;
  bool _showMyPostsOnly = false;
  final ScrollController _scrollController = ScrollController();
  int _loadedPostCount = 5;
  static const int _loadMoreThreshold = 2;
  bool _isLoadingMore = false;
  final Set<String> _expandedPosts = <String>{};
  static const int _maxLinesCollapsed = 3;
  final Set<String> _hiddenPostIds = <String>{};
  PostModel? _recentlyHiddenPost;

  @override
  void initState() {
    super.initState();
    _sharingState = context.read<SharingState>();
    final dataBinding = SharingDataBinding(sharingState: _sharingState);

    _eventHandler = SharingEventHandler(
      sharingState: _sharingState,
      dataBinding: dataBinding,
    );

    _eventHandler.init();

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoadingMore &&
        _scrollController.position.extentAfter <
            _loadMoreThreshold * MediaQuery.of(context).size.height / 6) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_sharingState.posts.length > _loadedPostCount) {
      setState(() {
        _isLoadingMore = true;
        _loadedPostCount += 5;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _isLoadingMore = false;
      });
    }
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

  void _showPostOptions(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            if (post.userId == widget.user.userId)
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
                    _eventHandler.deletePost(post.id!);
                  }
                },
              ),
            if (post.userId == widget.user.userId)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: Text(post.isPublic ? 'Make Private' : 'Make Public'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmVisibility = await showConfirmDialog(
                    context,
                    post.isPublic ? 'Make Private' : 'Make Public',
                    post.isPublic
                        ? 'Are you sure you want to make this post private?'
                        : 'Are you sure you want to make this post public?',
                  );
                  if (confirmVisibility) {
                    _eventHandler.togglePostVisibility(post.id!);
                  }
                },
              ),
            if (post.userId != widget.user.userId)
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text("I don't want to see this post"),
                onTap: () {
                  Navigator.pop(context);
                  _hidePost(post);
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

  void _hidePost(PostModel post) {
    Provider.of<SharingState>(context, listen: false).hidePost(post.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post hidden.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            Provider.of<SharingState>(
              context,
              listen: false,
            ).unhidePost(post.id!);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharingState>(
      builder: (context, sharingState, child) {
        final filteredPosts =
            _showMyPostsOnly
                ? sharingState.posts
                    .where((post) => post.userId == widget.user.userId)
                    .toList()
                : sharingState.posts;

        final displayedPosts =
            filteredPosts
                .where((post) => !sharingState.hiddenPostIds.contains(post.id))
                .take(_loadedPostCount)
                .toList();

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(title: const Text("Sharing Space")),
              body: Column(
                children: [
                  _buildCreatePostButton(),
                  _buildToggleButtons(),
                  Expanded(
                    child:
                        _showMyPostsOnly
                            ? MyPostsList(
                              posts: displayedPosts,
                              userId: widget.user.userId,
                              loadedPostCount: _loadedPostCount,
                              isLoadingMore: _isLoadingMore,
                              scrollController: _scrollController,
                              expandedPosts: _expandedPosts,
                              maxLinesCollapsed: _maxLinesCollapsed,
                              onShowPostOptions:
                                  (post) => _showPostOptions(context, post),
                              onPlayMusic:
                                  (post) =>
                                      _eventHandler.playMusic(post.musicUrl!),
                              getTimeAgo: getTimeAgo,
                              onExpand: (postId) {
                                setState(() {
                                  _expandedPosts.add(postId);
                                });
                              },
                              onCollapse: (postId) {
                                setState(() {
                                  _expandedPosts.remove(postId);
                                });
                              },
                              onViewTripJournal: _showTripJournalDialog,
                            )
                            : _buildSharedContentList(displayedPosts),
                  ),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            if (sharingState.currentMusicUrl != null)
              FloatingMusicPlayer(
                youtubeUrl: sharingState.currentMusicUrl!,
                onClose: () {
                  _eventHandler.closeMusic();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildCreatePostButton() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/default_pic.jpg'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await _eventHandler.navigateToCreatePost(context, widget.user);
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
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomButton(
            text: "All Posts",
            onPressed: () {
              setState(() {
                _showMyPostsOnly = false;
                _loadedPostCount = 5;
                _scrollController.jumpTo(0);
                _expandedPosts.clear();
              });
            },
            backgroundColor: !_showMyPostsOnly ? Colors.blue : Colors.grey,
            horizontalPadding: 20,
            verticalPadding: 10,
            borderRadius: 20,
            fontSize: 14,
          ),
          const SizedBox(width: 10),
          CustomButton(
            text: "My Posts",
            onPressed: () {
              setState(() {
                _showMyPostsOnly = true;
                _loadedPostCount = 5;
                _scrollController.jumpTo(0);
                _expandedPosts.clear();
              });
            },
            backgroundColor: _showMyPostsOnly ? Colors.blue : Colors.grey,
            horizontalPadding: 20,
            verticalPadding: 10,
            borderRadius: 20,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  // Now uses UI components for "All Posts" view
  Widget _buildSharedContentList(List<PostModel> posts) {
    if (_sharingState.isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty && !_sharingState.isLoading) {
      return const Center(child: Text("No posts available."));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount:
          posts.length + (_sharingState.posts.length > posts.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < posts.length) {
          final post = posts[index];
          final isTripJournal = post.postType == PostType.tripJournal;

          return PostCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // PostHeader (contains the 3-dots button at the end)
                    Expanded(
                      child: PostHeader(
                        userName:
                            post.userId == widget.user.userId
                                ? "You"
                                : "Depression People",
                        avatarAsset: 'assets/default_pic.jpg',
                        timeAgo: getTimeAgo(post.timestamp),
                        isPublic: post.isPublic,
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
                if (post.content.isNotEmpty)
                  PostContent(
                    content: post.content,
                    isExpanded: _expandedPosts.contains(post.id),
                    maxLinesCollapsed: _maxLinesCollapsed,
                    onExpand: () {
                      setState(() {
                        _expandedPosts.add(post.id!);
                      });
                    },
                    onCollapse: () {
                      setState(() {
                        _expandedPosts.remove(post.id);
                      });
                    },
                  ),
                if (post.musicUrl != null)
                  PostMusicPreview(
                    musicUrl: post.musicUrl,
                    musicTitle: post.musicTitle,
                    onPlay: () => _eventHandler.playMusic(post.musicUrl!),
                  ),
              ],
            ),
          );
        } else if (_sharingState.posts.length > posts.length &&
            !_sharingState.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          return Container();
        }
      },
    );
  }

  /// Dialog to show trip journal details
  void _showTripJournalDialog(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Trip Journal Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      post.location ?? 'Unknown location',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      post.tripDate != null
                          ? '${post.tripDate!.day}/${post.tripDate!.month}/${post.tripDate!.year}'
                          : 'Unknown date',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
