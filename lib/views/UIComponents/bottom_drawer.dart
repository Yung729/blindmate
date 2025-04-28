import 'dart:async';

import 'package:flutter/material.dart';

class BottomDrawer extends StatefulWidget {
  final Function(dynamic) onFlowerSelected;
  final Function(String) onStickerSelected;
  final Function() onPlayMiniGame;
  final Function() onShareMusic;
  final Function() onTripJournal;

  final List<String> stickerList;

  final bool showStickers; 
  final Function(bool) toggleStickers;
  final Function(String) onStickerSearch;
  final int flowerCount; 

  const BottomDrawer({
    super.key,
    required this.onFlowerSelected,
    required this.onStickerSelected,
    required this.onPlayMiniGame,
    required this.onShareMusic,
    required this.onTripJournal,
    required this.stickerList,
    required this.showStickers,
    required this.toggleStickers,
    required this.onStickerSearch,
    required this.flowerCount, 
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
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7;
    final screenWidth = MediaQuery.of(context).size.width;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        width: screenWidth,
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.showStickers) ...[
              SizedBox(
                width: screenWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDrawerButton(
                        icon: Icons.local_florist,
                        label: "Flower",
                        onTap: () => widget.onFlowerSelected(null),
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
                        onTap: () => widget.toggleStickers(true),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              _buildStickerDrawer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isFlower = label == "Flower";
    final bool hasFlowers = widget.flowerCount > 0;

    return GestureDetector(
      onTap: isFlower && !hasFlowers ? null : onTap,
      child: Container(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFlower && !hasFlowers 
                    ? Colors.grey[100]
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isFlower && !hasFlowers 
                        ? Colors.grey[400]
                        : Colors.grey[700],
                  ),
                  if (isFlower && hasFlowers)
                    Positioned(
                      right: -12,
                      top: -12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            widget.flowerCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isFlower && !hasFlowers 
                    ? Colors.grey[400]
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerDrawer() {
    final screenHeight = MediaQuery.of(context).size.height;
    final gridHeight = screenHeight * 0.25;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search stickers...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          // No onChanged handler - search only happens on button press
                        ),
                      ),
                      // Search button
                      IconButton(
                        icon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        onPressed: () {
                          final query = _searchController.text.trim();
                          if (query.length >= 3) {
                            widget.onStickerSearch(query);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      widget.toggleStickers(false);
                      _searchController.clear();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(),
        ),
        Container(
          height: gridHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.vertical,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.stickerList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => widget.onStickerSelected(widget.stickerList[index]),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.network(
                    widget.stickerList[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
