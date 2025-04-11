import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/user_model.dart';
import '../../viewmodels/state/sharing_state.dart';
import '../../viewmodels/dataBinding/sharing_data_binding.dart';
import '../../viewmodels/eventHandlers/sharing_event_handler.dart';
import '../UIComponents/floating_music_player.dart';
import '../UIComponents/custom_button.dart';
import '../../models/dataModels/post_model.dart';
import '../UIComponents/post_privacy_indicator.dart'; // Import the privacy indicator

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
                onTap: () {
                  Navigator.pop(context);
                  _eventHandler.deletePost(post.id!);
                },
              ),
            if (post.userId == widget.user.userId)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: Text(post.isPublic ? 'Make Private' : 'Make Public'),
                onTap: () {
                  Navigator.pop(context);
                  _eventHandler.togglePostVisibility(post.id!);
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
        final filteredPosts =
            _showMyPostsOnly
                ? sharingState.posts
                    .where((post) => post.userId == widget.user.userId)
                    .toList()
                : sharingState.posts;

        final displayedPosts = filteredPosts.take(_loadedPostCount).toList();

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(title: const Text("Sharing Space")),
              body: Column(
                children: [
                  _buildCreatePostButton(),
                  _buildToggleButtons(),
                  Expanded(child: _buildSharedContentList(displayedPosts)),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
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
          final videoId = _eventHandler.getYouTubeVideoId(post.musicUrl ?? "");

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/default_pic.jpg'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.userId == widget.user.userId
                                  ? "You"
                                  : "Depression People",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // In your _buildSharedContentList method:
                            Row(
                              children: [
                                Text(
                                  getTimeAgo(post.timestamp),
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 120, 120, 120),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                PostPrivacyIndicator(
                                  privacy: post.isPublic ? 'public' : 'private',
                                  size:
                                      14,
                                  color:
                                      Colors
                                          .black54,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (post.userId == widget.user.userId)
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showPostOptions(context, post),
                        )
                      else
                        const Icon(Icons.more_vert),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (post.content.isNotEmpty) Text(post.content),
                  const SizedBox(height: 8),
                  if (videoId != null)
                    GestureDetector(
                      onTap: () => _eventHandler.playMusic(post.musicUrl!),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              height: 70,
                              child: Image.network(
                                "http://img.youtube.com/vi/$videoId/0.jpg",
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.music_note,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Spacer(),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
}
