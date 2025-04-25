import 'package:flutter/material.dart';
import './floating_music_player.dart';

/// A manager for the music player overlay
class MusicOverlayManager {
  static final MusicOverlayManager _instance = MusicOverlayManager._internal();
  
  factory MusicOverlayManager() {
    return _instance;
  }
  
  MusicOverlayManager._internal();
  
  OverlayEntry? _currentMusicOverlay;
  
  /// Play music in a floating overlay
  void playMusic(BuildContext context, String youtubeUrl) {
    // Close any existing player first
    closeMusic();
    
    // Create a new overlay entry for the music player
    _currentMusicOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 100, // Position at top to avoid chat input
        right: 20,
        child: FloatingMusicPlayer(
          youtubeUrl: youtubeUrl,
          onClose: closeMusic,
        ),
      ),
    );
    
    // Insert the overlay
    Overlay.of(context).insert(_currentMusicOverlay!);
  }
  
  /// Close the music player
  void closeMusic() {
    if (_currentMusicOverlay != null) {
      _currentMusicOverlay!.remove();
      _currentMusicOverlay = null;
    }
  }
  
  /// Check if music is currently playing
  bool get isPlaying => _currentMusicOverlay != null;
}
