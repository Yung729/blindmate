
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A book-like, swipeable widget to display trip journal entries.
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
          // Book "spine" shadow
          Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.brown[200],
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 4/5,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.brown[50],
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [Colors.brown[50]!, Colors.brown[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Book "page" top decoration
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.brown[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.book, color: Colors.brown[300], size: 22),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.green, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.green,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.date_range, color: Colors.blueGrey, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                // Description section
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.short_text, color: Colors.teal, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          description,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // Note section (legacy)
                                if (note.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes, color: Colors.orange, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          note,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 16,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const Spacer(),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    'Page ${index + 1} of ${journals.length}',
                                    style: TextStyle(
                                      color: Colors.brown[300],
                                      fontSize: 13,
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
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(journals.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.brown[400]
                              : Colors.brown[200],
                          borderRadius: BorderRadius.circular(4),
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
