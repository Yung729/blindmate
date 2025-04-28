import 'package:blindmate/models/dataModels/user_model.dart';
import 'package:blindmate/models/dataModels/mission_model.dart'; // Make sure MissionModel is imported
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoMissionHandler {
  final UserModel user; // The user who is performing the mission
  // final MissionService missionService; // Service to fetch or assign missions

  DoMissionHandler({required this.user});

  // Assign the selected mission to the user's current mission
  Future<void> assignMissionToUser(
    BuildContext context,
    MissionModel selectedMission,
  ) async {
    try {
      // Check if the mission is valid and the user can proceed with it
      if (selectedMission != null) {
        print("Assigning mission '${selectedMission.title}' to user...");

        // Update Firestore with the new current mission
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.userId)
            .update({
              'currentMission': selectedMission.id, // Convert mission to map
            });

        // 2. Update the selected mission's 'selected' field to true
        await FirebaseFirestore.instance
            .collection('missions')
            .doc(selectedMission.id)
            .update({'selected': true});

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mission "${selectedMission.title}" assigned successfully!',
            ),
          ),
        );
      } else {
        print("Invalid mission selected.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mission selection failed. Try again.')),
        );
      }
    } catch (e) {
      print("Error assigning mission: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error assigning mission: $e')));
    }
  }
}
