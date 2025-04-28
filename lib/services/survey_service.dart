import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SurveyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if survey dialog should be shown
  Future<bool> shouldShowSurveyDialog(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Timestamp? surveyTimestamp = userDoc.get('surveyDate') as Timestamp?;
        Timestamp? dialogTimestamp = userDoc.get('popDialog') as Timestamp?;
        bool shouldShowDialog = false;

        // Check if 7 or more days have passed since the last survey
        if (surveyTimestamp != null) {
          DateTime surveyDate = surveyTimestamp.toDate();
          DateTime today = DateTime.now();
          int daysDifference = today.difference(surveyDate).inDays;

          if (daysDifference >= 7) {
            // Check if dialog was shown today
            if (dialogTimestamp != null) {
              DateTime lastDialogDate = dialogTimestamp.toDate();
              DateTime todayStart =
                  DateTime(today.year, today.month, today.day, 0, 0, 0);
              shouldShowDialog = lastDialogDate.isBefore(todayStart);
            } else {
              shouldShowDialog = true;
            }
          }
        } else {
          shouldShowDialog = true; 
        }

        return shouldShowDialog;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking survey status: $e');
      return false;
    }
  }

  // Update popDialog timestamp
  Future<void> updatePopDialogTimestamp(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'popDialog': Timestamp.fromDate(
          DateTime.now(), 
        ),
      });
    } catch (e) {
      print('Error updating popDialog: $e');
    }
  }

  // Show survey dialog
  void showSurveyDialog(BuildContext context, String userId, VoidCallback onSurveyAccepted) {
    updatePopDialogTimestamp(userId); // Use the actual userId

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Survey Invitation'),
        content: const Text(
          'Would you like to answer survey question?\nNote: It may increase your level.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onSurveyAccepted();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}