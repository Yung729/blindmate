import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripJournalPreview extends StatelessWidget {
  final List<Map<String, dynamic>> journals;
  final VoidCallback onTap;

  const TripJournalPreview({
    super.key,
    required this.journals,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (journals.isEmpty) return const SizedBox.shrink();

    final firstJournal = journals.first;
    final location = firstJournal['location'] as String?;
    final firstTimestamp = firstJournal['date'] as Timestamp?;
    final firstDate = firstTimestamp?.toDate();

    final lastJournal = journals.last;
    final lastTimestamp = lastJournal['date'] as Timestamp?;
    final lastDate = lastTimestamp?.toDate();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.teal.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Location with icon
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tour,  // Changed to a more attractive icon
                          color: Colors.teal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          location ?? 'Unknown Location',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Journey days badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${journals.length} ${journals.length == 1 ? 'Day' : 'Days'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date range with icon
            if (firstDate != null) 
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: Colors.teal.shade300,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      journals.length > 1 && lastDate != null
                          ? '${_formatDate(firstDate)} - ${_formatDate(lastDate)}'
                          : _formatDate(firstDate),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Tap for more details button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.teal.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 18,
                    color: Colors.teal.shade300,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to view journey details',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}