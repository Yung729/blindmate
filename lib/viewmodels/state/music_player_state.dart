import 'package:flutter/foundation.dart';

class MusicPlayerState extends ChangeNotifier {
  String? _currentMusicUrl;
  String? _currentMusicTitle;
  bool _isPlaying = false;
  bool _isMinimized = false;

  // Getters
  String? get currentMusicUrl => _currentMusicUrl;
  String? get currentMusicTitle => _currentMusicTitle;
  bool get isPlaying => _isPlaying;
  bool get isMinimized => _isMinimized;
  bool get hasMusicLoaded => _currentMusicUrl != null;

  // Play a new music track
  void playMusic(String url, String? title) {
    if (_currentMusicUrl != url) {
      _currentMusicUrl = url;
      _currentMusicTitle = title;
      _isPlaying = true;
      _isMinimized = false;
      notifyListeners();
    } else if (!_isPlaying) {
      // Resume the current track
      _isPlaying = true;
      notifyListeners();
    }
  }

  // Pause current music
  void pauseMusic() {
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Resume current music
  void resumeMusic() {
    if (!_isPlaying && _currentMusicUrl != null) {
      _isPlaying = true;
      notifyListeners();
    }
  }

  // Stop music completely and clear the current track
  void stopMusic() {
    _currentMusicUrl = null;
    _currentMusicTitle = null;
    _isPlaying = false;
    _isMinimized = false;
    notifyListeners();
  }

  // Toggle between minimized and expanded player view
  void toggleMinimized() {
    _isMinimized = !_isMinimized;
    notifyListeners();
  }

  // Set minimized state directly
  void setMinimized(bool minimized) {
    if (_isMinimized != minimized) {
      _isMinimized = minimized;
      notifyListeners();
    }
  }
}
