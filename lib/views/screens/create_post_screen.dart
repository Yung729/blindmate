import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/user_model.dart';
import '../../services/gemini_moderation_service.dart';
import '../../viewmodels/dataBinding/create_post_data_binding.dart';
import '../../viewmodels/eventHandlers/create_post_event_handler.dart';
import '../../viewmodels/state/create_post_state.dart';
import '../../viewmodels/uiValidation/post_validator.dart';
import '../UIComponents/loading_indicator.dart'; // Import the UIComponents

class CreatePostScreen extends StatefulWidget {
  final UserModel user;

  const CreatePostScreen({super.key, required this.user});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late TextEditingController _textController;
  late CreatePostEventHandler _eventHandler;
  final ScrollController _scrollController = ScrollController();
  final GeminiModerationService _moderationService = GeminiModerationService();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );
    final dataBinding = CreatePostDataBinding(createPostState: createPostState);

    _eventHandler = CreatePostEventHandler(
      createPostState: createPostState,
      dataBinding: dataBinding,
      user: widget.user,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showMusicSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final musicSearchController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final createPostState = Provider.of<CreatePostState>(context);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Search Music",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: musicSearchController,
                      onChanged: (text) => _eventHandler.handleMusicSearch(text),
                      decoration: InputDecoration(
                        hintText: "Search for a song...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        suffixIcon: const Icon(Icons.search, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  if (createPostState.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: UIComponents.loadingIndicator()), // Default size
                    ),
                  if (createPostState.musicResults.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: createPostState.musicResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(
                              createPostState.musicResults[index]['title']!,
                            ),
                            onTap: () {
                              _eventHandler.selectMusic(
                                createPostState.musicResults[index]['url']!,
                                createPostState.musicResults[index]['title']!,
                              );
                              Navigator.pop(context); // Close the dialog
                            },
                          );
                        },
                      ),
                    ),
                  if (createPostState.musicResults.isEmpty &&
                      !createPostState.isLoading &&
                      musicSearchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No music found."),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleSharePost(BuildContext context) async {
    final postContent = _textController.text;

    if (!UIValidation.isPostContentValid(postContent)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Post content cannot be empty!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    Provider.of<CreatePostState>(context, listen: false).setIsLoading(true);

    // Call Gemini moderation service
    final moderationResult = await _moderationService.checkContentLevel(postContent);

    // Hide loading indicator
    if (context.mounted) {
      Provider.of<CreatePostState>(context, listen: false).setIsLoading(false);
    }

    if (moderationResult == 'UNSAFE') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your post content has been flagged as inappropriate and cannot be shared."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Proceed with sharing the post if it's SAFE or WARNING
    await _eventHandler.sharePost();
    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );
    createPostState.reset();
    _textController.clear();

    if (context.mounted) {
      Navigator.pop(context);
      if (moderationResult == 'WARNING') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your post has been shared but contains potentially sensitive content."),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post shared successfully!"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create post",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack( // Use Stack to overlay loading indicator
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: Provider.of<CreatePostState>(context).isLoading
                      ? null // Disable the button when loading is true
                      : () => _handleSharePost(context),
                  color: Colors.black,
                ),
                if (Provider.of<CreatePostState>(context).isLoading)
                  UIComponents.loadingIndicator(width: 24, height: 24), // Specify size
              ],
            ),
          ),
        ],
      ),
      body: Consumer<CreatePostState>(
        builder: (context, createPostState, child) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info section
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/default_profile.png'),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "You",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "& Pablo",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Post content field
                TextField(
                  controller: _textController,
                  maxLines: null,
                  onChanged: (value) => _eventHandler.updatePostContent(value),
                  decoration: const InputDecoration(
                    hintText: "What's on your head?",
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Selected music display
                if (createPostState.selectedMusicUrl != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            createPostState.selectedMusicTitle ?? "Selected song",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        // Add remove button
                        InkWell(
                          onTap: () {
                            _eventHandler.selectMusic(null, null);
                          },
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: InkWell(
          onTap: () => _showMusicSearchDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.music_note),
                const SizedBox(width: 8),
                const Text(
                  "Add Music",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}