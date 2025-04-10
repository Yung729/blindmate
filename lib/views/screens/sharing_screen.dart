import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/user_model.dart';
import '../../viewmodels/state/sharing_state.dart';
import '../../viewmodels/dataBinding/sharing_data_binding.dart';
import '../../viewmodels/eventHandlers/sharing_event_handler.dart';
import '../UIComponents/floating_music_player.dart';
import '../UIComponents/fetch_url_thumbail.dart';
import '../UIComponents/custom_button.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharingState>(
      builder: (context, sharingState, child) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text("Sharing Space"),
              ),
              body: Column(
                children: [
                  _buildCreatePostButton(),
                  _buildToggleButtons(),
                  Expanded(child: _buildSharedContentList(sharingState)),
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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

  Widget _buildSharedContentList(SharingState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredPosts = _showMyPostsOnly
        ? state.posts.where((post) => post.userId == widget.user.userId).toList()
        : state.posts;

    return ListView.builder(
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        final videoId = _eventHandler.getYouTubeVideoId(post.musicUrl ?? "");

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10.0),
            // Removed the border here
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
                        children: const [
                          Text("Depression People", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Just Now", style: TextStyle(color: Color.fromARGB(255, 120, 120, 120))),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert),
                  ],
                ),
                const SizedBox(height: 8),
                if (post.content.isNotEmpty)
                  Text(post.content),
                const SizedBox(height: 8),
                if (videoId != null)
                  GestureDetector(
                    onTap: () => _eventHandler.playMusic(post.musicUrl!),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        // Removed the border here as well
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 70,
                            child: Image.network(
                              "http://img.youtube.com/vi/$videoId/mqdefault.jpg",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.music_note, size: 30, color: Colors.grey));
                              },
                            ),
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.play_circle_fill, color: Colors.blue, size: 30),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Implement link preview if needed
              ],
            ),
          ),
        );
      },
    );
  }
}