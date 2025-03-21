import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MusicPlayerScreen extends StatefulWidget {
  final String youtubeUrl;

  const MusicPlayerScreen({super.key, required this.youtubeUrl});

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isVideoEnded = false;
  String songTitle = "Unknown Title";
  String artistName = "Unknown Artist";
  double _volume = 100;
  double _currentPosition = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId!,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    )..addListener(_videoListener);

    // Simulate getting song metadata
    setState(() {
      songTitle = "Sample Song";
      artistName = "Sample Artist";
    });

    // Update progress bar every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentPosition = _controller.value.position.inSeconds.toDouble();
        });
      }
    });
  }

  void _videoListener() {
    if (_controller.value.playerState == PlayerState.ended) {
      setState(() {
        _isVideoEnded = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Music Player",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Album Art
              Container(
                height: screenHeight * 0.3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage("assets/album_cover.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Song Title & Artist Name
              Text(
                songTitle,
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                artistName,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              if (!_isVideoEnded) ...[
                IgnorePointer(
                  child: SizedBox(
                    width: screenWidth * 0.9,
                    child: YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: false,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Play/Pause Button (Fixed)
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: screenWidth * 0.15,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Volume Adjuster
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0,
                        max: 100,
                        divisions: 10,
                        label: "${_volume.round()}%",
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                            _controller.setVolume(value.toInt());
                          });
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white),
                  ],
                ),
              ],

              // Progress Bar (Always Visible, Fixed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatTime(_currentPosition.toInt()),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentPosition,
                      min: 0,
                      max: (_controller.metadata.duration.inSeconds > 0)
                          ? _controller.metadata.duration.inSeconds.toDouble()
                          : 1,
                      onChanged: (value) {
                        setState(() {
                          _currentPosition = value; // Update UI immediately
                        });
                      },
                      onChangeEnd: (value) {
                        _controller.seekTo(Duration(seconds: value.toInt()));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                  Text(
                    formatTime(_controller.metadata.duration.inSeconds),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),

              // Show Replay & Exit buttons when video ends
              if (_isVideoEnded) ...[
                const SizedBox(height: 20),
                Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isVideoEnded = false;
                          _controller.seekTo(Duration.zero);
                          _controller.play();
                        });
                      },
                      icon: const Icon(Icons.replay, color: Colors.white),
                      label: const Text("Replay", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      label: const Text("Exit", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
