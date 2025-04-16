
// lib/widgets/music_search_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/create_post_state.dart';
import '../../viewmodels/eventHandlers/music_search_event_handler.dart';
import '../UIComponents/loading_indicator.dart';

class MusicSearchDialog extends StatefulWidget {
  final Function(String url, String title) onMusicSelected;
  
  const MusicSearchDialog({
    Key? key,
    required this.onMusicSelected,
  }) : super(key: key);

  // Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    required Function(String url, String title) onMusicSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: MusicSearchDialog(
            onMusicSelected: onMusicSelected,
          ),
        );
      },
    );
  }

  @override
  _MusicSearchDialogState createState() => _MusicSearchDialogState();
}

class _MusicSearchDialogState extends State<MusicSearchDialog> {
  final TextEditingController _musicSearchController = TextEditingController();
  late MusicSearchEventHandler _musicSearchHandler;

  @override
  void initState() {
    super.initState();
    final createPostState = Provider.of<CreatePostState>(context, listen: false);
    _musicSearchHandler = MusicSearchEventHandler(createPostState: createPostState);
  }

  @override
  void dispose() {
    _musicSearchController.dispose();
    super.dispose();
  }

  void _handleMusicSelection(String url, String title) {
    // Call the callback function
    widget.onMusicSelected(url, title);
    
    // Close the dialog with a short delay to ensure state changes are processed
    Future.delayed(Duration.zero, () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _triggerSearch() {
    _musicSearchHandler.handleMusicSearch(_musicSearchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CreatePostState>(
      builder: (context, createPostState, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Search Music",
                      style: TextStyle(
                        fontSize: 20,
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
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _musicSearchController,
                  decoration: InputDecoration(
                    hintText: "Search for a song...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.music_note, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.blue),
                      onPressed: _triggerSearch,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  autofocus: true,
                  onSubmitted: (text) => _triggerSearch(),
                ),
              ),
              const SizedBox(height: 12),
              // Loading indicator or results
              if (createPostState.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: UIComponents.loadingIndicator()),
                )
              else if (createPostState.musicResults.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: createPostState.musicResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 70),
                    itemBuilder: (context, index) {
                      final musicItem = createPostState.musicResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.music_note, color: Colors.blue),
                        ),
                        title: Text(
                          musicItem['title']!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: musicItem['artist'] != null 
                            ? Text(musicItem['artist']!) 
                            : null,
                        onTap: () {
                          _handleMusicSelection(
                            musicItem['url']!,
                            musicItem['title']!,
                          );
                        },
                      );
                    },
                  ),
                )
              else if (!createPostState.isLoading &&
                  _musicSearchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        "No music found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
