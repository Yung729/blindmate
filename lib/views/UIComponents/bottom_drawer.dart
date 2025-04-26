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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildDrawerButton(
                          icon: Icons.local_florist,
                          label: "Flower",
                          onTap: () => widget.onFlowerSelected(null),
                        ),
                        const SizedBox(width: 12),
                        _buildDrawerButton(
                          icon: Icons.music_note,
                          label: "Music",
                          onTap: widget.onShareMusic,
                        ),
                        const SizedBox(width: 12),
                        _buildDrawerButton(
                          icon: Icons.travel_explore,
                          label: "Journal",
                          onTap: widget.onTripJournal,
                        ),
                        const SizedBox(width: 12),
                        _buildDrawerButton(
                          icon: Icons.videogame_asset,
                          label: "Game",
                          onTap: widget.onPlayMiniGame,
                        ),
                        const SizedBox(width: 12),
                        _buildDrawerButton(
                          icon: Icons.sticky_note_2,
                          label: "Sticker",
                          onTap: () => widget.toggleStickers(true),
                        ),
                      ],
                    ),
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
        width: 65, // Fixed width for consistent sizing
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46, // Fixed width for icon container
              height: 46, // Fixed height for icon container
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isFlower && !hasFlowers 
                  ? Colors.grey[100] 
                  : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      : const Color(0xFF2C2C2E),
                  ),
                  if (isFlower && hasFlowers)
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
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
                  : const Color(0xFF2C2C2E),
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
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
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
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
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
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
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
        const SizedBox(height: 4),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      height: 60,
                      width: 60,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
