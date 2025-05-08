import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/eventHandlers/create_post_event_handler.dart';
import '../../viewmodels/state/create_post_state.dart';
import '../../viewmodels/state/auth_state.dart';
import '../../viewmodels/state/do_mission_state.dart';
import '../../viewmodels/uiValidation/post_validator.dart';
import '../UIComponents/loading_indicator.dart';
import '../UIComponents/url_input_dialog.dart';
import '../UIComponents/music_search_dialog.dart';
import '../UIComponents/trip_journal_create_dialog.dart';
import '../../utils/fetch_url_thumbail.dart';
import '../UIComponents/custom_snackbar.dart';
import '../UIComponents/custom_dialog.dart';
import '../UIComponents/post_music_preview.dart';

class CreatePostScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CreatePostScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen>
    with WidgetsBindingObserver {
  late TextEditingController _textController;
  late CreatePostEventHandler _eventHandler;
  final ScrollController _scrollController = ScrollController();
  bool _isPosting = false;
  Map<String, String>? _cachedMetadata; // Cache for fetched metadata
  bool _isMetadataFetched = false;
  List<Map<String, dynamic>> _pastJournals = [];

  String _formatDateRange(List<Map<String, dynamic>> journals) {
    if (journals.isEmpty) return '';
    final dates =
        journals.map((j) => j['date']).whereType<DateTime>().toList()..sort();
    if (dates.isEmpty) return '';
    final first = dates.first;
    final last = dates.last;
    if (first == last) {
      return '${first.day}/${first.month}/${first.year}';
    } else {
      return '${first.day}/${first.month}/${first.year} - ${last.day}/${last.month}/${last.year}';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController = TextEditingController();

    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );
    
    // Get mission state
    final missionState = Provider.of<MissionState>(
      context,
      listen: false,
    );

    // Fetch avatar from AuthState for event handler
    final authState = Provider.of<AuthState>(context, listen: false);
    final userAvatar = authState.currentUser?.avatarImg ?? '';

    // Use factory constructor with mission state
    _eventHandler = CreatePostEventHandler.withMissionState(
      createPostState: createPostState,
      missionState: missionState,
      userId: widget.userId,
      userName: widget.userName,
      userAvatar: userAvatar,
    );

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    // Check if there's a saved draft
    final hasDraft = await _eventHandler.hasDraft();

    if (hasDraft && mounted) {
      final shouldLoadDraft = await showConfirmDialog(
        context,
        "Draft Found",
        "A saved draft was found. Would you like to load it?",
      );
      if (shouldLoadDraft == true) {
        await _eventHandler.loadDraft();

        // Update the text controller with the loaded content
        if (mounted) {
          final state = Provider.of<CreatePostState>(context, listen: false);
          _textController.text = state.postContent;
        }
      } else {
        // Clear the draft if user chooses not to load it
        await _eventHandler.clearDraft();

        // --- Reset UI state here ---
        if (mounted) {
          final createPostState = Provider.of<CreatePostState>(
            context,
            listen: false,
          );
          createPostState.reset();
          _textController.clear();
        }
        setState(() {
          _cachedMetadata = null;
          _isMetadataFetched = false;
        });
        // --- End reset ---
      }
    }

    // Fetch past trip journals
    await _fetchPastJournals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-save draft when the app is paused (user switches away from the app)
    if (state == AppLifecycleState.paused) {
      _saveAsDraftIfNeeded(autoSave: true);
    }
  }

  Future<void> _fetchPastJournals() async {
    final journals = await _eventHandler.loadUserTripJournals();
    setState(() {
      _pastJournals = journals;
    });
  }

  void _openMusicSearch() {
    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );
    if (createPostState.tripJournals.isNotEmpty) {
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
      initialEntries: createPostState.tripJournals,
      onJournalsAdded: (entries) {
        createPostState.setTripJournals(entries);
        setState(() {});
      },
      pastJournals: _pastJournals,
    );
  }

  Future<void> _handleSharePost(BuildContext context) async {
    final postContent = _textController.text;
    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );

    final isValid = UIValidation.isPostValid(
      postContent: postContent,
      musicUrl: createPostState.selectedMusicUrl,
      linkUrl: createPostState.selectedLinkUrl,
      tripJournals: createPostState.tripJournals,
    );

    if (!isValid) {
      CustomSnackBar.show(
        context: context,
        message: "Post cannot be empty!",
        status: "ERROR",
      );
      return;
    }

    // Prevent both music and trip journal
    if (createPostState.selectedMusicUrl != null &&
        createPostState.tripJournals.isNotEmpty) {
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
      await _eventHandler.sharePost(tripJournals: createPostState.tripJournals);

      createPostState.reset();
      _textController.clear();

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

  bool _hasUnsavedContent() {
    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );
    return _textController.text.trim().isNotEmpty ||
        createPostState.selectedLinkUrl != null ||
        createPostState.selectedMusicUrl != null ||
        createPostState.tripJournals.isNotEmpty;
  }

  Future<void> _saveAsDraftIfNeeded({bool autoSave = false}) async {
    if (_hasUnsavedContent()) {
      final createPostState = Provider.of<CreatePostState>(
        context,
        listen: false,
      );
      // Update state with current content
      createPostState.setPostContent(_textController.text);
      await _eventHandler.saveToDraft();
      if (!autoSave && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Draft saved!")));
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isPosting) return false; // Prevent pop while posting

    if (_hasUnsavedContent()) {
      final result = await showSaveDraftDialog(
        context,
        "Unsaved Changes",
        "You have unsaved changes. Would you like to discard, cancel, or save as draft?",
      );
      if (result == 'discard') {
        await _eventHandler.clearDraft();

        // --- Reset UI state after saving draft ---
        if (mounted) {
          final createPostState = Provider.of<CreatePostState>(
            context,
            listen: false,
          );
          createPostState.reset();
          _textController.clear();
          setState(() {
            _cachedMetadata = null;
            _isMetadataFetched = false;
          });
        }
        // --- End reset ---

        return true;
      } else if (result == 'save') {
        await _saveAsDraftIfNeeded();

        // --- Reset UI state after discarding draft ---
        if (mounted) {
          final createPostState = Provider.of<CreatePostState>(
            context,
            listen: false,
          );
          createPostState.reset();
          _textController.clear();
          setState(() {
            _cachedMetadata = null;
            _isMetadataFetched = false;
          });
        }
        // --- End reset ---

        return true;
      } else {
        // Cancel
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
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
                        Consumer<AuthState>(
                          builder: (context, authState, _) {
                            final avatarUrl =
                                authState.currentUser?.avatarImg ?? '';
                            return Container(
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
                                    avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : const AssetImage(
                                              'assets/default_profile.png',
                                            )
                                            as ImageProvider,
                              ),
                            );
                          },
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
                            SizedBox(
                              height: 32,
                              child: Consumer<CreatePostState>(
                                builder: (context, createPostState, _) {
                                  return PopupMenuButton<String>(
                                    onSelected: (value) {
                                      createPostState.setIsPublic(
                                        value == "Public",
                                      );
                                    },
                                    itemBuilder:
                                        (BuildContext context) => [
                                          const PopupMenuItem<String>(
                                            value: "Public",
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.public,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 8),
                                                Text("Public"),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: "Private",
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.lock,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 8),
                                                Text("Private"),
                                              ],
                                            ),
                                          ),
                                        ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            createPostState.isPublic
                                                ? Icons.public
                                                : Icons.lock,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            createPostState.isPublic
                                                ? "Public"
                                                : "Private",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
                                ? Future.value(_cachedMetadata)
                                : fetchUrlMetadata(
                                  createPostState.selectedLinkUrl!,
                                ),
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
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2),
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
                                      _cachedMetadata = null;
                                      _isMetadataFetched = false;
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
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail section
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Builder(
                                  builder: (context) {
                                    final videoId = const PostMusicPreview(
                                      musicUrl: '',
                                      musicTitle: '',
                                    ).extractYoutubeId(
                                      createPostState.selectedMusicUrl,
                                    );

                                    return videoId != null
                                        ? Image.network(
                                          "https://img.youtube.com/vi/$videoId/mqdefault.jpg",
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: Colors.blue.withValues(
                                                alpha: 0.1,
                                              ),
                                              child: const Icon(
                                                Icons.music_note,
                                                color: Colors.blue,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                        );
                                  },
                                ),
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
                    if (createPostState.tripJournals.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.2),
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
                                      '${createPostState.tripJournals.first['location']} (${_formatDateRange(createPostState.tripJournals)})',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      Provider.of<CreatePostState>(
                                        context,
                                        listen: false,
                                      ).clearTripJournals();
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Consumer<CreatePostState>(
              builder: (context, createPostState, child) {
                final urlAdded = createPostState.selectedLinkUrl != null;
                final musicAdded = createPostState.selectedMusicUrl != null;
                final tripJournalAdded =
                    createPostState.tripJournals.isNotEmpty;

                final urlDisabled = musicAdded || tripJournalAdded;
                final musicDisabled = urlAdded || tripJournalAdded;
                final tripJournalDisabled = urlAdded || musicAdded;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add URL
                    InkWell(
                      onTap:
                          urlDisabled
                              ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "You cannot add a URL when music or a trip journal is attached.",
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              : () {
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
                      child: Opacity(
                        opacity: urlDisabled ? 0.5 : 1.0,
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
                                Icons.link,
                                color: Colors.blue,
                                size: 20,
                              ),
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
                    ),
                    const SizedBox(height: 8),

                    // Add Music
                    InkWell(
                      onTap:
                          musicDisabled
                              ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "You cannot add music when a URL or trip journal is attached.",
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

                    // Add Trip Journal
                    InkWell(
                      onTap:
                          tripJournalDisabled
                              ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "You cannot add a trip journal when a URL or music is attached.",
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
                                color: Colors.blue,
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
      ),
    );
  }
}
