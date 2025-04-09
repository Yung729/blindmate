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
  });

  @override
  _BottomDrawerState createState() => _BottomDrawerState();
}

class _BottomDrawerState extends State<BottomDrawer> {

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
            SizedBox(
              height: 120, // Adjust height to fit two rows of stickers
              child: GridView.builder(
                scrollDirection: Axis.horizontal, // Horizontal scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two rows
                  crossAxisSpacing: 8, // Spacing between columns
                  mainAxisSpacing: 8, // Spacing between rows
                  childAspectRatio: 1, // Square stickers
                ),
                itemCount: widget.stickerList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => widget.onStickerSelected(widget.stickerList[index]),
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
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}