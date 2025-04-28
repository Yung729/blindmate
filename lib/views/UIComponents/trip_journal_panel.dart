import 'package:flutter/material.dart';
import 'trip_journal_preview.dart';

class TripJournalPanel extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final String Function(DateTime) getTimeAgo;
  final Function(BuildContext, Map<String, dynamic>) onViewTripJournal;
  final VoidCallback onClose;
  final bool isSelectionMode;
  final Function(Map<String, dynamic>)? onSelect;
  final String? title;

  const TripJournalPanel({
    Key? key,
    required this.posts,
    required this.getTimeAgo,
    required this.onViewTripJournal,
    required this.onClose,
    this.isSelectionMode = false,
    this.onSelect,
    this.title,
  }) : super(key: key);

  @override
  State<TripJournalPanel> createState() => _TripJournalPanelState();
}

class _TripJournalPanelState extends State<TripJournalPanel> {
  @override
  Widget build(BuildContext context) {
    final tripJournals =
        widget.posts
            .where((post) => post['postType'] == 'tripJournal')
            .where((post) => post['tripJournals']?.isNotEmpty ?? false)
            .toList();

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
                      // Replace the Text widget in the header with:
                      Text(
                        widget.title ??
                            (widget.isSelectionMode
                                ? "Select Trip Journal"
                                : "Trip Journals (${tripJournals.length})"),
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
                  child:
                      tripJournals.isEmpty
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
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final post = tripJournals[index];
                              return InkWell(
                                onTap:
                                    widget.isSelectionMode
                                        ? () {
                                          widget.onSelect?.call(post);
                                          Navigator.pop(context);
                                        }
                                        : () => widget.onViewTripJournal(
                                          context,
                                          post,
                                        ),
                                child: TripJournalPreview(
                                  journals: post['tripJournals']!,
                                  onTap:
                                      widget.isSelectionMode
                                          ? () {
                                            widget.onSelect?.call(post);
                                            Navigator.pop(context);
                                          }
                                          : () => widget.onViewTripJournal(
                                            context,
                                            post,
                                          ),
                                ),
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
