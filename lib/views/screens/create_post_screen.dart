import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dataModels/user_model.dart';
import '../../services/gemini_moderation_service.dart';
import '../../viewmodels/dataBinding/create_post_data_binding.dart';
import '../../viewmodels/eventHandlers/create_post_event_handler.dart';
import '../../viewmodels/state/create_post_state.dart';
import '../../viewmodels/uiValidation/post_validator.dart';
import '../UIComponents/loading_indicator.dart';
import '../UIComponents/music_search_dialog.dart'; // Import our new widget

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
  bool _isPosting = false;

  // Trip Journal state
  String? _tripLocation;
  DateTime? _tripDate;

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
    MusicSearchDialog.show(
      context,
      onMusicSelected: (url, title) {
        // Update the state through the event handler
        _eventHandler.selectMusic(url, title);

        // Force a rebuild of the UI
        setState(() {});
      },
    );
  }

  Future<void> _openTripJournalDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => _TripJournalFieldsDialog(
            initialLocation: _tripLocation,
            initialDate: _tripDate,
          ),
    );
    if (result != null) {
      setState(() {
        _tripLocation = result['location'];
        _tripDate = result['tripDate'];
      });
    }
  }

  Future<void> _handleSharePost(BuildContext context) async {
    final postContent = _textController.text;

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

    // Show posting status
    setState(() {
      _isPosting = true;
    });

    // Call Gemini moderation service
    final moderationResult = await _moderationService.checkContentLevel(
      postContent,
    );

    // Posting completed
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

    // Proceed with sharing the post if it's SAFE or WARNING
    await _eventHandler.sharePost(location: _tripLocation, tripDate: _tripDate);
    final createPostState = Provider.of<CreatePostState>(
      context,
      listen: false,
    );
    createPostState.reset();
    _textController.clear();
    setState(() {
      _tripLocation = null;
      _tripDate = null;
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
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                            'assets/default_profile.png',
                          ),
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
                          // Add remove button
                          IconButton(
                            onPressed: () {
                              _eventHandler.selectMusic(null, null);
                            },
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // Trip Journal info display
                  if (_tripLocation != null && _tripDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
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
                            const Icon(Icons.location_on, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$_tripLocation (${_tripDate!.day}/${_tripDate!.month}/${_tripDate!.year})',
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
                                  _tripLocation = null;
                                  _tripDate = null;
                                });
                              },
                            ),
                          ],
                        ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _openMusicSearch,
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
              const SizedBox(height: 8),
              InkWell(
                onTap: _openTripJournalDialog,
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
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog for entering Trip Journal fields
class _TripJournalFieldsDialog extends StatefulWidget {
  final String? initialLocation;
  final DateTime? initialDate;

  const _TripJournalFieldsDialog({this.initialLocation, this.initialDate});

  @override
  State<_TripJournalFieldsDialog> createState() =>
      _TripJournalFieldsDialogState();
}

class _TripJournalFieldsDialogState extends State<_TripJournalFieldsDialog> {
  final _formKey = GlobalKey<FormState>();
  String _location = '';
  DateTime? _tripDate;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation ?? '';
    _tripDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trip Journal Details'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Enter location' : null,
              onChanged: (v) => _location = v,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tripDate == null
                        ? 'Select Date'
                        : '${_tripDate!.day}/${_tripDate!.month}/${_tripDate!.year}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _tripDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _tripDate = picked);
                    }
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _tripDate != null) {
              Navigator.pop(context, {
                'location': _location,
                'tripDate': _tripDate,
              });
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
