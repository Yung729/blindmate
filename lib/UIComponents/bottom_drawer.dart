import 'package:flutter/material.dart';

class BottomDrawer extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final Function(String) onStickerSelected;
  final Function() onPlayMiniGame;
  final Function() onShareMusic;
  final Function() onTripJournal;

  final List<String> emojiList;
  final List<String> stickerList;

  const BottomDrawer({
    super.key,
    required this.onEmojiSelected,
    required this.onStickerSelected,
    required this.onPlayMiniGame,
    required this.onShareMusic,
    required this.onTripJournal,
    required this.emojiList,
    required this.stickerList,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: Icon(Icons.emoji_emotions)),
              Tab(icon: Icon(Icons.sticky_note_2)),
              Tab(icon: Icon(Icons.videogame_asset)),
              Tab(icon: Icon(Icons.music_note)),
              Tab(icon: Icon(Icons.travel_explore)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildEmojiPicker(),
                _buildStickerPicker(),
                _buildMiniGamePicker(),
                _buildMusicPicker(),
                _buildTripJournalPicker(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: emojiList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onEmojiSelected(emojiList[index]),
          child: Center(
            child: Text(
              emojiList[index],
              style: const TextStyle(fontSize: 20), // Adjusted font size
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickerPicker() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: stickerList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onStickerSelected(stickerList[index]),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.network(
              stickerList[index],
              height: 80, // Adjusted height
              width: 80, // Adjusted width
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniGamePicker() {
    return Center(
      child: ElevatedButton(
        onPressed: onPlayMiniGame,
        child: const Text("Play Mini Game"),
      ),
    );
  }

  Widget _buildMusicPicker() {
    return Center(
      child: ElevatedButton(
        onPressed: onShareMusic,
        child: const Text("Share Music"),
      ),
    );
  }

  Widget _buildTripJournalPicker() {
    return Center(
      child: ElevatedButton(
        onPressed: onTripJournal,
        child: const Text("Trip Journal"),
      ),
    );
  }
}