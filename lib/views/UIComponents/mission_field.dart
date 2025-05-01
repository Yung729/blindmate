import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:blindmate/models/dataModels/mission_model.dart';

class MissionField extends StatelessWidget {
  final MissionModel mission;
  final bool isCurrentMission;
  final VoidCallback? onTap;

  const MissionField({
    Key? key,
    required this.mission,
    required this.isCurrentMission,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
        Container(
        padding: EdgeInsets.all(12.0),
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFD9D9D9),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Stack(
  children: [
    // Background bar
    Container(
      height: 20,
      decoration: BoxDecoration(
        color: Color(0xFF8FC3D3),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Color.fromRGBO(237, 233, 247, 0.69),
          width: 1.0,
        ),
      ),
    ),

    // Filled progress
    FractionallySizedBox(
      widthFactor: (mission.progress / (mission.requirements.target == 0 ? 1 : mission.requirements.target)).clamp(0.0, 1.0),
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
    ),

    // Progress text in the middle
    Positioned.fill(
      child: Center(
        child: Text(
          '${mission.progress}/${mission.requirements.target}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
),

          ],
        ),
      ),
      // if (isCurrentMission)
      //       Positioned.fill(
      //         child: ClipRRect(
      //           borderRadius: BorderRadius.circular(12.0),
      //           child: BackdropFilter(
      //             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      //             child: Container(
      //               alignment: Alignment.center,
      //               color: Colors.black.withOpacity(0.3),
      //               child: Text(
      //                 "Invalid Option",
      //                 style: TextStyle(
      //                   color: Colors.white,
      //                   fontSize: 20,
      //                   fontWeight: FontWeight.bold,
      //                 ),
      //               ),
      //             ),
      //           ),
      //         ),
      //       ),
        ],
      ),
    );
  }
}