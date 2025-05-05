import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/music_player_state.dart';
import 'loading_indicator.dart';

class FloatingYoutubePlayer extends StatefulWidget {
  final String youtubeUrl;
  final String? title;

  const FloatingYoutubePlayer({
    super.key,
    required this.youtubeUrl,
    this.title,
  });

  @override
  State<FloatingYoutubePlayer> createState() => _FloatingYoutubePlayerState();
}

class _FloatingYoutubePlayerState extends State<FloatingYoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  YoutubePlayerController? _controller;
  String? _videoId;
  bool _isPlaying = false;
  bool _isReady = false;
  bool _isInitializing = true; // Start with initializing set to true
  bool _isLoading = true; // Start with loading set to true
  double _sliderValue = 0.0;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant FloatingYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.youtubeUrl != oldWidget.youtubeUrl) {
      _safeDisposeController();
      _videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isReady = false;
          _isInitializing = true; // Set to true when URL changes
          _isLoading = true; // Set to true when URL changes
          _sliderValue = 0.0;
        });
      }
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    if (_videoId == null || _isDisposed) return;
    
    setState(() {
      _isInitializing = true;
      _isLoading = true;
    });
    
    _controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true, 
        mute: false,
        hideControls: true,
        enableCaption: false,
        forceHD: false,
      ),
    );
    
    if (!_isDisposed) {
      _controller!.addListener(_listener);
    }
  }

  void _safeDisposeController() {
    if (_controller != null) {
      try {
        if (!_isDisposed) {
          _controller!.removeListener(_listener);
        }
        
        // Pause before disposing to avoid race conditions
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        }
        
        // Use Future.microtask to ensure proper disposal sequence
        Future.microtask(() {
          try {
            _controller?.dispose();
          } catch (e) {
            debugPrint('Error disposing controller: $e');
          }
          _controller = null;
        });
      } catch (e) {
        debugPrint('Error during controller cleanup: $e');
        _controller = null;
      }
    }
  }

  void _listener() {
    if (!mounted || _isDisposed || _controller == null) return;
    
    try {
      final value = _controller!.value;
      if (mounted) {
        setState(() {
          _sliderValue = value.position.inSeconds.toDouble();

          // Update ready state when player is initialized
          if (!_isReady && value.isReady) {
            _isReady = true;
            // Even when ready, keep loading state true until actually playing
            if (!value.isPlaying) {
              _isLoading = true;
            }
          }

          // Update loading state based on player state
          if (value.isPlaying) {
            _isLoading = false;
            _isInitializing = false;
            _isPlaying = true;

            // Update the global music state
            final musicState = Provider.of<MusicPlayerState>(
              context,
              listen: false,
            );
            if (musicState.currentMusicUrl == widget.youtubeUrl &&
                !musicState.isPlaying) {
              musicState.resumeMusic();
            }
          } else {
            _isPlaying = false;
            
            // Keep loading state true if not yet played
            if (!value.hasPlayed) {
              _isLoading = true;
            }
            
            final musicState = Provider.of<MusicPlayerState>(
              context,
              listen: false,
            );
            if (musicState.currentMusicUrl == widget.youtubeUrl &&
                musicState.isPlaying) {
              musicState.pauseMusic();
            }
            
            // Handle errors and video end
            if (value.hasError) {
              _isLoading = false;
              _isInitializing = false;
            }
            if (value.position >= value.metaData.duration) {
              _isLoading = false;
              _isInitializing = false;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error in YouTube player listener: $e');
    }
  }

  Future<void> _handlePlayPause() async {
    if (_controller == null || _isDisposed) return;

    final musicState = Provider.of<MusicPlayerState>(context, listen: false);

    try {
      if (_controller!.value.isPlaying && _controller!.value.isReady) {
        _controller!.pause();
        if (mounted) {
          setState(() {
            _isPlaying = false;
            // We'll keep loading state true if it hasn't been played before
            if (!_controller!.value.hasPlayed) {
              _isLoading = true;
            } else {
              _isLoading = false;
            }
            _isInitializing = false;
          });
        }

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

      if (mounted) {
        setState(() {
          _isLoading = true;
          _isInitializing = true;
        });
      }

      if (!_isReady) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (!_isDisposed && !_isReady && _controller != null) {
          _controller!.load(_videoId!);

          // Wait for player to be ready, with timeout
          int attempts = 0;
          const maxAttempts = 50; // 5 seconds timeout
          while (!_isReady && mounted && !_isDisposed && _controller != null && attempts < maxAttempts) {
            await Future.delayed(const Duration(milliseconds: 100));
            attempts++;
          }
        }
      }

      if (mounted && !_isDisposed && _controller != null && _controller!.value.isReady) {
        // Ensure video is at beginning if it's ended
        if (_controller!.value.position >= _controller!.metadata.duration) {
          _controller!.seekTo(const Duration(seconds: 0));
        }

        _controller!.play();

        // Update the global music state
        musicState.playMusic(widget.youtubeUrl, widget.title);
      }
    } catch (e) {
      debugPrint('Error in play/pause handler: $e');
      if (mounted) {
        setState(() {
          _isLoading = true; // Keep loading indicator visible on error
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void deactivate() {
    // Pause playback when widget is deactivated (e.g., navigating away)
    if (_controller?.value.isPlaying ?? false) {
      _controller?.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _safeDisposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isDisposed) {
      return const SizedBox.shrink();
    }
    
    return Consumer<MusicPlayerState>(
      builder: (context, musicState, child) {
        // Determine if we should show loading state
        bool shouldShowLoading = _isInitializing || _isLoading || 
            (_controller != null && !_controller!.value.isPlaying && 
             !_controller!.value.hasPlayed);
        
        // Keep player state in sync with global music state
        if (!_isDisposed && _controller != null &&
            musicState.currentMusicUrl == widget.youtubeUrl) {
          if (musicState.isPlaying &&
              !_controller!.value.isPlaying &&
              _controller!.value.isReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposed && _controller != null &&
                  _controller!.value.isReady) {
                _controller!.play();
              }
            });
          } else if (!musicState.isPlaying &&
              _controller != null &&
              _controller!.value.isPlaying &&
              _controller!.value.isReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposed && _controller != null) {
                _controller!.pause();
              }
            });
          }
        } else if (!_isDisposed && _controller != null && _controller!.value.isPlaying) {
          // If another track is playing in the global state, pause this one
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isDisposed && _controller != null) {
              _controller!.pause();
            }
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
                  color: Colors.black.withValues(alpha: 0.2),
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
                          "https://img.youtube.com/vi/$_videoId/mqdefault.jpg",
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
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hidden video player (required for audio playback)
                if (!_isDisposed && _controller != null)
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      height: 0,
                      width: 0,
                      child: YoutubePlayer(
                        controller: _controller!,
                        showVideoProgressIndicator: false,
                        onReady: () {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _isReady = true;
                              // Keep loading true until first play
                              _isInitializing = false;
                            });
                          }
                        },
                        onEnded: (metaData) {
                          if (mounted && !_isDisposed) {
                            // Hide the widget by stopping music when the song ends
                            Provider.of<MusicPlayerState>(
                              context,
                              listen: false,
                            ).stopMusic();
                          }
                        },
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
                                      icon: shouldShowLoading
                                          ? UIComponents.loadingIndicator(
                                              width: 24,
                                              height: 24,
                                              strokeWidth: 2,
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
                                    child: (!_isDisposed && _controller != null)
                                        ? ValueListenableBuilder<YoutubePlayerValue>(
                                            valueListenable: _controller!,
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
                                                        inactiveTrackColor:
                                                            Colors.white.withValues(alpha: 0.3),
                                                        thumbColor: Colors.white,
                                                        overlayColor:
                                                            Colors.white.withValues(alpha: 0.2),
                                                      ),
                                                      child: Slider(
                                                        value: _sliderValue,
                                                        max: value.metaData.duration.inSeconds
                                                            .toDouble()
                                                            .clamp(1, double.infinity),
                                                        onChanged: (newValue) {
                                                          if (mounted && !_isDisposed) {
                                                            setState(() {
                                                              _sliderValue = newValue;
                                                            });
                                                            if (_controller != null &&
                                                                _controller!.value.isReady) {
                                                              _controller!.seekTo(
                                                                Duration(
                                                                  seconds: newValue.toInt(),
                                                                ),
                                                              );
                                                            }
                                                          }
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
                                                            MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            _formatDuration(value.position),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.white
                                                                  .withValues(alpha: 0.7),
                                                            ),
                                                          ),
                                                          Text(
                                                            _formatDuration(
                                                                value.metaData.duration),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.white
                                                                  .withValues(alpha: 0.7),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  // --- CLOSE BUTTON ---
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      context.read<MusicPlayerState>().stopMusic();
                                    },
                                    tooltip: 'Close Player',
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
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}