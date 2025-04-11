import 'dart:async';

import 'package:flutter/material.dart';

class BottomDrawer extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final Function(String) onStickerSelected;
  final Function() onPlayMiniGame;
  final Function() onShareMusic;
  final Function() onTripJournal;

  final List<String> stickerList;

  final bool showStickers; // Add this parameter
  final Function(bool) toggleStickers;
  final Function(String) onStickerSearch;

  const BottomDrawer({
    super.key,
    required this.onEmojiSelected,
    required this.onStickerSelected,
    required this.onPlayMiniGame,
    required this.onShareMusic,
    required this.onTripJournal,
    required this.stickerList,
    required this.showStickers,
    required this.toggleStickers,
    required this.onStickerSearch,
  });

  @override
  _BottomDrawerState createState() => _BottomDrawerState();
}

class _BottomDrawerState extends State<BottomDrawer> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.showStickers) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDrawerButton(
                  icon: Icons.emoji_emotions,
                  label: "Emoji",
                  onTap: () => widget.onEmojiSelected("😊"),
                ),
                _buildDrawerButton(
                  icon: Icons.music_note,
                  label: "Music",
                  onTap: widget.onShareMusic,
                ),
                _buildDrawerButton(
                  icon: Icons.travel_explore,
                  label: "Journal",
                  onTap: widget.onTripJournal,
                ),
                _buildDrawerButton(
                  icon: Icons.videogame_asset,
                  label: "Game",
                  onTap: widget.onPlayMiniGame,
                ),
                _buildDrawerButton(
                  icon: Icons.sticky_note_2,
                  label: "Sticker",
                  onTap: () {
                    setState(() {
                      widget.toggleStickers(true);
                    });
                  },
                ),
              ],
            ),
          ] else ...[
            _buildStickerDrawer(),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStickerDrawer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        Container(
          height: 40, // Fixed height for search bar
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stickers...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(width: 1),
                    ),
                    isDense: true, // Makes the TextField more compact
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    // Changed from onSubmitted to onChanged
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 500),
                      () {
                        if (value.isNotEmpty) {
                          widget.onStickerSearch(value);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    widget.toggleStickers(false);
                    _searchController.clear();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Sticker grid
        SizedBox(
          height: 120,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.stickerList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap:
                    () => widget.onStickerSelected(widget.stickerList[index]),
                child: Image.network(
                  widget.stickerList[index],
                  height: 50,
                  width: 50,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
