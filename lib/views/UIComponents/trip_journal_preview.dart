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

    // Get the last date if there are multiple entries
    final lastJournal = journals.last;
    final lastTimestamp = lastJournal['date'] as Timestamp?;
    final lastDate = lastTimestamp?.toDate();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location ?? 'Unknown Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            if (firstDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, 
                    color: Colors.grey[600], 
                    size: 16
                  ),
                  const SizedBox(width: 4),
                  Text(
                    journals.length > 1 && lastDate != null
                        ? '${_formatDate(firstDate)} - ${_formatDate(lastDate)}'
                        : _formatDate(firstDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (journals.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                '${journals.length} days journey',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}