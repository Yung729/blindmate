
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A reusable widget to display a list of trip journal entries.
/// Each entry should be a Map with at least 'location', 'date', and optionally 'note'.
class TripJournalList extends StatelessWidget {
  final List<Map<String, dynamic>> journals;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const TripJournalList({
    Key? key,
    required this.journals,
    this.showDivider = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (journals.isEmpty) {
      return const Center(
        child: Text(
          'No trip journal entries.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(0),
      itemCount: journals.length,
      separatorBuilder: (_, __) =>
          showDivider ? const Divider(height: 20, thickness: 1, color: Color(0xFFE0E0E0)) : SizedBox.shrink(),
      itemBuilder: (context, index) {
        final journal = journals[index];
        final location = journal['location'] ?? 'Unknown location';
        final dateRaw = journal['date'];
        DateTime? date;
        if (dateRaw is Timestamp) {
          date = dateRaw.toDate();
        } else if (dateRaw is String) {
          date = DateTime.tryParse(dateRaw);
        } else if (dateRaw is DateTime) {
          date = dateRaw;
        }
        final dateStr = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : 'Unknown date';
        final note = journal['note'] ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    location,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.blueGrey, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
