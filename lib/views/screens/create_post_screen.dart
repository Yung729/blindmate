import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/user_model.dart';
import '../../viewmodels/dataBinding/create_post_data_binding.dart';
import '../../viewmodels/eventHandlers/create_post_event_handler.dart';
import '../../viewmodels/state/create_post_state.dart';
import '../../viewmodels/uiValidation/post_validator.dart';
import '../UIComponents/loading_indicator.dart';
import '../UIComponents/url_input_dialog.dart';
import '../UIComponents/music_search_dialog.dart';
import '../UIComponents/trip_journal_create_dialog.dart';
import '../UIComponents/fetch_url_thumbail.dart';

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
  bool _isPosting = false;
  Map<String, String>? _cachedMetadata; // Cache for fetched metadata
  bool _isMetadataFetched = false;

  // Trip Journal state (multi-entry)
  List<Map<String, dynamic>> _tripJournals = [];

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

  void _openMusicSearch() {
    if (_tripJournals.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "You cannot add music when a trip journal is attached.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    MusicSearchDialog.show(
      context,
      onMusicSelected: (url, title) {
        _eventHandler.selectMusic(url, title);
        setState(() {});
      },
    );
  }

  Future<void> _openTripJournalDialog() async {
    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );
    if (createPostState.selectedMusicUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "You cannot add a trip journal when music is attached.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await TripJournalDialog.show(
      context,
      initialEntries: _tripJournals,
      onJournalsAdded: (entries) {
        setState(() {
          _tripJournals = entries;
        });
      },
      pastJournals: [],
    );
  }

  Future<void> _handleSharePost(BuildContext context) async {
    final postContent = _textController.text;
    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );

    // Prevent both music and trip journal
    if (createPostState.selectedMusicUrl != null && _tripJournals.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "You cannot attach both music and trip journal to a post.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!UIValidation.isPostContentValid(postContent)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Post content cannot be empty!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            left: 20,
            right: 20,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      // Use the event handler to check content moderation
      final moderationResult = await _eventHandler.checkContentModeration(
        postContent,
      );

      setState(() {
        _isPosting = false;
      });

      if (moderationResult == 'UNSAFE') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Your post content has been flagged as inappropriate and cannot be shared.",
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      // Pass the list of trip journals to your event handler (update your handler if needed)
      await _eventHandler.sharePost(tripJournals: _tripJournals);

      createPostState.reset();
      _textController.clear();
      setState(() {
        _tripJournals = [];
      });

      if (context.mounted) {
        Navigator.pop(context);
        if (moderationResult == 'WARNING') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Your post has been shared but contains potentially sensitive content.",
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Post shared successfully!"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isPosting = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _onUrlChanged(String url) {
    setState(() {
      _cachedMetadata = null; // Clear cached metadata
      _isMetadataFetched = false; // Reset the flag
    });
  }

  void _togglePostVisibility() {
    Provider.of<CreatePostState>(context, listen: false).setIsPublic(
      !Provider.of<CreatePostState>(context, listen: false).isPublic,
    );
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
          "Create Post",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child:
                _isPosting
                    ? Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      child: UIComponents.loadingIndicator(
                        width: 24,
                        height: 24,
                      ),
                    )
                    : ElevatedButton(
                      onPressed: () => _handleSharePost(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text("Post"),
                    ),
          ),
        ],
      ),
      body: Consumer<CreatePostState>(
        builder: (context, createPostState, child) {
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info section
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              (widget.user.avatarImg.isNotEmpty)
                                  ? NetworkImage(widget.user.avatarImg)
                                  : const AssetImage(
                                        'assets/default_profile.png',
                                      )
                                      as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                          GestureDetector(
                            onTap: _togglePostVisibility,
                            child: Row(
                              children: [
                                Text(
                                  createPostState.isPublic
                                      ? "Public"
                                      : "Private",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  createPostState.isPublic
                                      ? Icons.public
                                      : Icons.lock,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Post content field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      minLines: 5,
                      onChanged:
                          (value) => _eventHandler.updatePostContent(value),
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected URL display
                  if (createPostState.selectedLinkUrl != null)
                    FutureBuilder<Map<String, String>?>(
                      future:
                          _isMetadataFetched
                              ? Future.value(
                                _cachedMetadata,
                              ) // Use cached metadata
                              : fetchUrlMetadata(
                                createPostState.selectedLinkUrl!,
                              ), // Fetch metadata
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const SizedBox.shrink();
                        }

                        // Cache the metadata and set the flag
                        if (!_isMetadataFetched) {
                          _cachedMetadata = snapshot.data!;
                          _isMetadataFetched = true;
                        }

                        final metadata = _cachedMetadata!;
                        final thumbnailUrl = metadata['image'];
                        final title = metadata['title'];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (thumbnailUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    thumbnailUrl,
                                    height: 40,
                                    width: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title ?? createPostState.selectedLinkUrl!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Provider.of<CreatePostState>(
                                    context,
                                    listen: false,
                                  ).clearLink();
                                  setState(() {
                                    _cachedMetadata =
                                        null; // Clear cached metadata
                                    _isMetadataFetched =
                                        false; // Reset the flag
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  // Selected music display
                  if (createPostState.selectedMusicUrl != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  createPostState.selectedMusicTitle ??
                                      "Selected song",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Music",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _eventHandler.selectMusic(null, null);
                              setState(() {});
                            },
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // Trip Journal info display (multi-entry)
                  if (_tripJournals.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        children:
                            _tripJournals.map((journal) {
                              final location = journal['location'] as String?;
                              final date = journal['date'] as DateTime?;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$location (${date != null ? '${date.day}/${date.month}/${date.year}' : ''})',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _tripJournals.remove(journal);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Consumer<CreatePostState>(
            builder: (context, createPostState, child) {
              final urlAdded = createPostState.selectedLinkUrl != null;
              final musicDisabled = urlAdded || _tripJournals.isNotEmpty;
              final tripJournalDisabled =
                  urlAdded || createPostState.selectedMusicUrl != null;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      UrlInputDialog.show(
                        context,
                        onUrlAdded: (url, thumbnail) {
                          Provider.of<CreatePostState>(
                            context,
                            listen: false,
                          ).setLink(url, thumbnail);
                          _onUrlChanged(url);
                          setState(() {});
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.link, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Add URL",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap:
                        musicDisabled
                            ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "You cannot add music when a trip journal is attached.",
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                            : _openMusicSearch,
                    borderRadius: BorderRadius.circular(12),
                    child: Opacity(
                      opacity: musicDisabled ? 0.5 : 1.0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.music_note,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Add Music",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap:
                        tripJournalDisabled
                            ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "You cannot add a trip journal when music is attached.",
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                            : _openTripJournalDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Opacity(
                      opacity: tripJournalDisabled ? 0.5 : 1.0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Trip Journal",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
