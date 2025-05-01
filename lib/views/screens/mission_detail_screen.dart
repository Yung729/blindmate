import 'package:blindmate/models/dataModels/mission_model.dart';
import 'package:flutter/material.dart';

class MissionDetailScreen extends StatefulWidget {
  final MissionModel mission;
  const MissionDetailScreen({super.key, required this.mission});

  @override
  _MissionDetailScreenState createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  // final MissionModel mission;
  // const _MissionDetailScreenState({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    double progress =
        (mission.progress ?? 0) / (mission.requirements.target ?? 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mission Details"),
        leading: BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      // backgroundColor: Colors.black,
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
                          // Title row with badge
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Text(
                          //       "Mission",
                          //       style: const TextStyle(
                          //         fontSize: 18,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 50),

                          // Mission name
                          Center(
                            child: Text(
                              mission.title,
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
                              Expanded(child: Text(mission.description)),
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
                              Text(mission.difficulty),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Reward
                          Row(
                            children: [
                              const Text(
                                "reward : ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(mission.rewards.xp.toString()),
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
                                widthFactor: (mission.progress /
                                        (mission.requirements.target == 0
                                            ? 1
                                            : mission.requirements.target))
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
                                    '${mission.progress}/${mission.requirements.target}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ), // Display task completion message if progress is full
                          if (mission.progress >= mission.requirements.target)
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
