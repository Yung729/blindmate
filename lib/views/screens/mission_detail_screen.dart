import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:flutter/material.dart';

class MissionDetailScreen extends StatefulWidget {
  final MissionModel mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  _MissionDetailScreenState createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  double _rewardRate = 1.0; // Default reward rate
  int _effectiveXp = 0; // Will store the adjusted XP

  @override
  void initState() {
    super.initState();
    _fetchRewardRate();
  }

  Future<void> _fetchRewardRate() async {
    try {
      // Fetch the reward rate from MissionModel
      final rewardRate = await widget.mission.getRewardRate();
      if (mounted) {
        setState(() {
          _rewardRate = rewardRate;
          _effectiveXp = widget.mission.rewards.getEffectiveXp(rewardRate);
        });
      }
    } catch (e) {
      print("Error fetching reward rate: $e");
      if (mounted) {
        setState(() {
          _rewardRate = 1.0; // Fallback to default rate
          _effectiveXp = widget.mission.rewards.xp; // Fallback to raw XP
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mission Details"),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Main content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    // Mission title section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50),

                          // Mission name
                          Center(
                            child: Text(
                              widget.mission.title,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // Mission details
                          Row(
                            children: [
                              const Text(
                                "description : ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(child: Text(widget.mission.description)),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Difficulty
                          Row(
                            children: [
                              const Text(
                                "difficulty: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(widget.mission.difficulty),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Reward (display effective XP with rate)
                          Row(
                            children: [
                              const Text(
                                "reward : ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "$_effectiveXp XP (${_rewardRate.toStringAsFixed(1)}x rate)",
                              ),
                            ],
                          ),

                          const SizedBox(height: 48),

                          // Progress bar
                          Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8FC3D3),
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: Border.all(
                                    color: const Color.fromRGBO(
                                      237,
                                      233,
                                      247,
                                      0.69,
                                    ),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (widget.mission.progress /
                                        (widget.mission.requirements.target == 0
                                            ? 1
                                            : widget.mission.requirements.target))
                                    .clamp(0.0, 1.0),
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Center(
                                  child: Text(
                                    '${widget.mission.progress}/${widget.mission.requirements.target}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Display task completion message if progress is full
                          if (widget.mission.progress >= widget.mission.requirements.target)
                            const Padding(
                              padding: EdgeInsets.only(top: 20.0),
                              child: Center(
                                child: Text(
                                  'Task Completed!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}