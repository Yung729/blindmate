import 'package:flutter/material.dart';
import 'trip_journal_preview.dart';
import 'trip_journal_card.dart';
import 'package:intl/intl.dart';

class TripJournalPanel extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final String Function(DateTime) getTimeAgo;
  final Function(BuildContext, Map<String, dynamic>) onViewTripJournal;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>)? onSelect;
  final String? title;

  const TripJournalPanel({
    Key? key,
    required this.posts,
    required this.getTimeAgo,
    required this.onViewTripJournal,
    required this.onClose,
    this.onSelect,
    this.title,
  }) : super(key: key);

  @override
  State<TripJournalPanel> createState() => _TripJournalPanelState();
}

class _TripJournalPanelState extends State<TripJournalPanel> {
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  void _showTripJournalDialog(BuildContext context, Map<String, dynamic> post) {
    final journals = List<Map<String, dynamic>>.from(
      post['tripJournals'] ?? [],
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.60,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TripJournalBookCard(
            journals: journals,
            padding: const EdgeInsets.all(0),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _selectJournal(Map<String, dynamic> post) {
    if (widget.onSelect != null) {
      widget.onSelect!(post);
      Navigator.pop(context);
    } else {
      widget.onViewTripJournal(context, post);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get trip journals and parse timestamps
    final List<Map<String, dynamic>> tripJournals = widget.posts
        .where((post) => post['postType'] == 'tripJournal')
        .where((post) => post['tripJournals']?.isNotEmpty ?? false)
        .map((post) {
          // Parse timestamp and add it to the post map
          DateTime? postTimestamp;
          try {
            if (post['timestamp'] != null) {
              postTimestamp = DateTime.parse(post['timestamp'].toString());
            }
          } catch (e) {
            print('Error parsing timestamp: $e');
            // Use a default timestamp in the past if parsing fails
            postTimestamp = DateTime(2000);
          }
          
          return {
            ...post,
            'parsedTimestamp': postTimestamp ?? DateTime(2000),
          };
        })
        .toList();
    
    // Sort the journals by timestamp, newest first
    tripJournals.sort((a, b) {
      final DateTime aTime = a['parsedTimestamp'] as DateTime;
      final DateTime bTime = b['parsedTimestamp'] as DateTime;
      return bTime.compareTo(aTime); // Reverse order for newest first
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle indicator
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 14, bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title ?? "Select Trip Journal",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 26),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                // List
                SizedBox(
                  height: 400, // Same fixed height as TripJournalDialog
                  child: tripJournals.isEmpty
                      ? const Center(
                          child: Text(
                            'No trip journals yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: tripJournals.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final post = tripJournals[index];
                            final DateTime postTimestamp = post['parsedTimestamp'] as DateTime;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Journal preview (clickable for selection)
                                InkWell(
                                  onTap: () => _selectJournal(post),
                                  child: TripJournalPreview(
                                    journals: post['tripJournals']!,
                                    onTap: () => _selectJournal(post),
                                    showExploreButton: false,
                                  ),
                                ),
                                // Row with timestamp and "Explore Journal Details" button
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Created date and time
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Posted ${_dateFormat.format(postTimestamp)} at ${_timeFormat.format(postTimestamp)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Explore Journal Details button
                                      TextButton.icon(
                                        onPressed: () => _showTripJournalDialog(context, post),
                                        icon: const Icon(Icons.book, size: 16),
                                        label: const Text(
                                          'Explore Journal Details',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}