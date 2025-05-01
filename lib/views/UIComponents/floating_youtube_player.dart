import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/state/music_player_state.dart';
import 'loading_indicator.dart';

class FloatingYoutubePlayer extends StatefulWidget {
  final String youtubeUrl;
  final String? title;
  final Key playerKey;

  const FloatingYoutubePlayer({
    Key? key,
    required this.youtubeUrl,
    this.title,
    required this.playerKey,
  }) : super(key: playerKey);

  @override
  State<FloatingYoutubePlayer> createState() => _FloatingYoutubePlayerState();
}

class _FloatingYoutubePlayerState extends State<FloatingYoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  YoutubePlayerController? _controller;
  String? _videoId;
  bool _isPlaying = false;
  bool _isReady = false;
  bool _isInitializing = false;
  bool _isLoading = false;
  double _sliderValue = 0.0;

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
      _disposeController();
      _videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
      _initializePlayer();
      setState(() {
        _isPlaying = false;
        _isReady = false;
        _isInitializing = false;
        _isLoading = false;
        _sliderValue = 0.0;
      });
    }
  }

  void _initializePlayer() {
    if (_videoId == null) return;
    _controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        enableCaption: false,
        forceHD: false,
      ),
    )..addListener(_listener);
  }

  void _disposeController() {
    if (_controller != null) {
      _controller!.removeListener(_listener);
      _controller!.dispose();
      _controller = null;
    }
  }

  void _listener() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    setState(() {
      _sliderValue = value.position.inSeconds.toDouble();

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
        final musicState = Provider.of<MusicPlayerState>(
          context,
          listen: false,
        );
        if (musicState.currentMusicUrl == widget.youtubeUrl &&
            musicState.isPlaying) {
          musicState.pauseMusic();
        }
        if (value.hasError) {
          _isLoading = false;
          _isInitializing = false;
        }
        if (value.position >= value.metaData.duration) {
          _isLoading = false;
          _isInitializing = false;
        }
      }

      // Update ready state when player is initialized
      if (!_isReady && value.isReady) {
        _isReady = true;
      }
    });
  }

  Future<void> _handlePlayPause() async {
    if (_isInitializing || _isLoading || _controller == null) return;

    final musicState = Provider.of<MusicPlayerState>(context, listen: false);

    if (_controller!.value.isPlaying && _controller!.value.isReady) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
        _isLoading = false;
        _isInitializing = false;
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
      _isLoading = true;
      _isInitializing = true;
    });

    if (!_isReady) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!_isReady && _controller != null) {
        _controller!.load(_videoId!);

        // Wait for player to be ready
        while (!_isReady && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    if (mounted && _controller != null && _controller!.value.isReady) {
      // Ensure video is at beginning if it's ended
      if (_controller!.value.position >= _controller!.metadata.duration) {
        _controller!.seekTo(const Duration(seconds: 0));
      }

      _controller!.play();

      // Update the global music state
      musicState.playMusic(widget.youtubeUrl, widget.title);

      // Loading indicator will be hidden by the listener when playback actually starts
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MusicPlayerState>(
      builder: (context, musicState, child) {
        // Keep player state in sync with global music state
        if (_controller != null &&
            musicState.currentMusicUrl == widget.youtubeUrl) {
          if (musicState.isPlaying &&
              !_controller!.value.isPlaying &&
              _controller!.value.isReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isLoading &&
                  !_isInitializing &&
                  _controller!.value.isReady) {
                _controller!.play();
              }
            });
          } else if (!musicState.isPlaying &&
              _controller!.value.isPlaying &&
              _controller!.value.isReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _controller!.pause();
            });
          }
        } else if (_controller != null && _controller!.value.isPlaying) {
          // If another track is playing in the global state, pause this one
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _controller!.pause();
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
                    child:
                        _controller != null
                            ? YoutubePlayer(
                              controller: _controller!,
                              showVideoProgressIndicator: false,
                            )
                            : null,
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
                                    child:
                                        _controller != null
                                            ? ValueListenableBuilder<
                                              YoutubePlayerValue
                                            >(
                                              valueListenable: _controller!,
                                              builder: (context, value, child) {
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      height: 20,
                                                      child: SliderTheme(
                                                        data: SliderThemeData(
                                                          trackHeight: 2,
                                                          thumbShape:
                                                              const RoundSliderThumbShape(
                                                                enabledThumbRadius:
                                                                    4,
                                                              ),
                                                          overlayShape:
                                                              const RoundSliderOverlayShape(
                                                                overlayRadius:
                                                                    8,
                                                              ),
                                                          activeTrackColor:
                                                              Colors.white,
                                                          inactiveTrackColor:
                                                              Colors.white
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                          thumbColor:
                                                              Colors.white,
                                                          overlayColor: Colors
                                                              .white
                                                              .withOpacity(0.2),
                                                        ),
                                                        child: Slider(
                                                          value: _sliderValue,
                                                          max: value
                                                              .metaData
                                                              .duration
                                                              .inSeconds
                                                              .toDouble()
                                                              .clamp(
                                                                1,
                                                                double.infinity,
                                                              ),
                                                          onChanged: (
                                                            newValue,
                                                          ) {
                                                            setState(() {
                                                              _sliderValue =
                                                                  newValue;
                                                            });
                                                            if (_controller!
                                                                .value
                                                                .isReady) {
                                                              _controller!.seekTo(
                                                                Duration(
                                                                  seconds:
                                                                      newValue
                                                                          .toInt(),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 14,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
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
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
                                                              ),
                                                            ),
                                                            Text(
                                                              _formatDuration(
                                                                value
                                                                    .metaData
                                                                    .duration,
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
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
                                      context
                                          .read<MusicPlayerState>()
                                          .stopMusic();
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
