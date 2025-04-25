
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A swipeable widget to display trip journal entries as cards.
/// Each entry is shown as a page; swipe horizontally to flip pages.
class TripJournalBookCard extends StatefulWidget {
  final List<Map<String, dynamic>> journals;
  final EdgeInsetsGeometry? padding;

  const TripJournalBookCard({
    Key? key,
    required this.journals,
    this.padding,
  }) : super(key: key);

  @override
  State<TripJournalBookCard> createState() => _TripJournalBookCardState();
}

class _TripJournalBookCardState extends State<TripJournalBookCard> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journals = widget.journals;
    if (journals.isEmpty) {
      return const Center(
        child: Text(
          'No trip journal entries.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 1.5, // Shorter card
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: journals.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
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
                    final description = journal['description'] ?? '';
                    final note = journal['note'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.brown[50],
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [Colors.brown[50]!, Colors.brown[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day X label at the top
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(
                                    'Day ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[400],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // Book "page" top decoration
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.brown[200],
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.book, color: Colors.brown[300], size: 18),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.green, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.green,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.date_range, color: Colors.blueGrey, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                // Description section
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.short_text, color: Colors.teal, size: 16),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // Note section (legacy)
                                if (note.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes, color: Colors.orange, size: 16),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          note,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 13,
                                            color: Colors.black87,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    'Page ${index + 1} of ${journals.length}',
                                    style: TextStyle(
                                      color: Colors.brown[300],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Page indicator (dots)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(journals.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 14 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.brown[400]
                              : Colors.brown[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
