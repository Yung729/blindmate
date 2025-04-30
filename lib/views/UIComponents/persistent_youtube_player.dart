import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/music_player_state.dart';
import 'loading_indicator.dart';

class PersistentYoutubePlayer extends StatefulWidget {
  final String youtubeUrl;
  final String? title;
  final Key playerKey;

  const PersistentYoutubePlayer({
    required this.youtubeUrl,
    this.title,
    required this.playerKey,
  });

  @override
  State<PersistentYoutubePlayer> createState() => _PersistentYoutubePlayerState();
}

class _PersistentYoutubePlayerState extends State<PersistentYoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  late YoutubePlayerController _controller;
  bool _isPlaying = false;
  bool _isReady = false;
  bool _isInitializing = false;
  bool _isLoading = false;
  String? _videoId;
  double _sliderValue = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: true,
        enableCaption: false,
        forceHD: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (mounted) {
      setState(() {
        _sliderValue = _controller.value.position.inSeconds.toDouble();

        // Update loading state based on player state
        if (_controller.value.isPlaying) {
          _isLoading = false;
          _isInitializing = false;
          _isPlaying = true;
          
          // Update the global music state
          final musicState = Provider.of<MusicPlayerState>(context, listen: false);
          if (musicState.currentMusicUrl == widget.youtubeUrl && !musicState.isPlaying) {
            musicState.resumeMusic();
          }
        } else {
          // When music is not playing (stopped, paused, or ended)
          _isPlaying = false;
          
          // Update the global music state
          final musicState = Provider.of<MusicPlayerState>(context, listen: false);
          if (musicState.currentMusicUrl == widget.youtubeUrl && musicState.isPlaying) {
            musicState.pauseMusic();
          }
          
          if (_controller.value.hasError) {
            _isLoading = false;
            _isInitializing = false;
          }
          
          // If we're at the end of the video
          if (_controller.value.position >= _controller.metadata.duration) {
            _isLoading = false;
            _isInitializing = false;
          }
        }

        // Update ready state when player is initialized
        if (!_isReady && _controller.value.isReady) {
          _isReady = true;
        }
      });
    }
  }

  Future<void> _handlePlayPause() async {
    if (_isInitializing || _isLoading) return;

    final musicState = Provider.of<MusicPlayerState>(context, listen: false);
    
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
      
      if (musicState.currentMusicUrl == widget.youtubeUrl) {
        musicState.pauseMusic();
      }
      return;
    }

    // If another music is playing, stop it first
    if (musicState.currentMusicUrl != null && 
        musicState.currentMusicUrl != widget.youtubeUrl) {
      musicState.stopMusic();
    }

    setState(() {
      _isLoading = true; // Show loading when attempting to play
    });

    if (!_isReady) {
      setState(() {
        _isInitializing = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!_isReady) {
        _controller.load(_videoId!);

        // Wait for player to be ready
        while (!_isReady && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    if (mounted) {
      // Ensure video is at beginning if it's ended
      if (_controller.value.position >= _controller.metadata.duration) {
        _controller.seekTo(const Duration(seconds: 0));
      }

      _controller.play();
      
      // Update the global music state
      musicState.playMusic(widget.youtubeUrl, widget.title);
      
      // Loading indicator will be hidden by the listener when playback actually starts
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MusicPlayerState>(
      builder: (context, musicState, child) {
        // Keep player state in sync with global music state
        if (musicState.currentMusicUrl == widget.youtubeUrl) {
          if (musicState.isPlaying && !_controller.value.isPlaying) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isLoading && !_isInitializing) {
                _controller.play();
              }
            });
          } else if (!musicState.isPlaying && _controller.value.isPlaying) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _controller.pause();
            });
          }
        } else if (_controller.value.isPlaying) {
          // If another track is playing in the global state, pause this one
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _controller.pause();
          });
        }
        
        return SizedBox(
          height: 96,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Thumbnail section
                if (_videoId != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          "http://img.youtube.com/vi/$_videoId/mqdefault.jpg",
                          height: 96,
                          width: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 96,
                              width: 96,
                              color: Colors.black12,
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 36,
                              ),
                            );
                          },
                        ),
                        Container(
                          height: 96,
                          width: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hidden video player (required for audio playback)
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 0,
                    width: 0,
                    child: YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: false,
                    ),
                  ),
                ),

                // Controls and info section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.title != null)
                              SizedBox(
                                height: 16,
                                child: Text(
                                  widget.title!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            const SizedBox(height: 4),

                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon:
                                          (_isInitializing || _isLoading)
                                              ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                              : Icon(
                                                _isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                      onPressed: _handlePlayPause,
                                    ),
                                  ),

                                  Expanded(
                                    child: ValueListenableBuilder<
                                      YoutubePlayerValue
                                    >(
                                      valueListenable: _controller,
                                      builder: (context, value, child) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              child: SliderTheme(
                                                data: SliderThemeData(
                                                  trackHeight: 2,
                                                  thumbShape:
                                                      const RoundSliderThumbShape(
                                                        enabledThumbRadius: 4,
                                                      ),
                                                  overlayShape:
                                                      const RoundSliderOverlayShape(
                                                        overlayRadius: 8,
                                                      ),
                                                  activeTrackColor: Colors.white,
                                                  inactiveTrackColor: Colors.white
                                                      .withOpacity(0.3),
                                                  thumbColor: Colors.white,
                                                  overlayColor: Colors.white
                                                      .withOpacity(0.2),
                                                ),
                                                child: Slider(
                                                  value: _sliderValue,
                                                  max:
                                                      value
                                                          .metaData
                                                          .duration
                                                          .inSeconds
                                                          .toDouble(),
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      _sliderValue = newValue;
                                                    });
                                                    _controller.seekTo(
                                                      Duration(
                                                        seconds: newValue.toInt(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 14,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      _formatDuration(
                                                        value.position,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatDuration(
                                                        value.metaData.duration,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
