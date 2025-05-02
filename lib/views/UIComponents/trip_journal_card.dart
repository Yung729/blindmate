
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripJournalBookCard extends StatefulWidget {
  final List<Map<String, dynamic>> journals;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onClose; // <-- Optional close button callback

  const TripJournalBookCard({
    Key? key,
    required this.journals,
    this.padding,
    this.onClose, // <-- Add to constructor
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

  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Sunset View':
        return Icons.wb_sunny;
      case 'Swimming':
        return Icons.pool;
      case 'Beach':
        return Icons.beach_access;
      case 'Hiking':
        return Icons.hiking;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Sightseeing':
        return Icons.photo_camera;
      case 'Water Sports':
        return Icons.surfing;
      case 'Nature':
        return Icons.park;
      case 'Cultural':
        return Icons.museum;
      default:
        return Icons.local_activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final journals = widget.journals;
    if (journals.isEmpty) {
      return const Center(
        child: Text(
          'No trip journal entries.',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      );
    }

    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 3.0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: AnimatedScale(
                          scale: _currentPage == index ? 1.0 : 0.97,
                          duration: const Duration(milliseconds: 300),
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade100,
                                    Colors.cyan.shade50,
                                    Colors.teal.shade100,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.10),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Decorative background image or pattern (optional)
                                  Positioned(
                                    right: -30,
                                    top: -30,
                                    child: Icon(
                                      Icons.beach_access,
                                      size: 100,
                                      color: Colors.blue.withOpacity(0.07),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top bar with Day indicator and optional Close button
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Day Ribbon (moved to left)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.teal[400],
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.teal.withOpacity(0.15),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                'Day ${index + 1}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            // Optional Close button
                                            if (widget.onClose != null)
                                              IconButton(
                                                onPressed: widget.onClose,
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Colors.white.withOpacity(0.9),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Location
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.blue[100],
                                              radius: 16,
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Colors.blueAccent,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                location,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                  color: Colors.blueAccent,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Date
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.teal[100],
                                              radius: 14,
                                              child: const Icon(
                                                Icons.calendar_month,
                                                color: Colors.teal,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Divider
                                        Divider(
                                          color: Colors.teal[100],
                                          thickness: 1,
                                          endIndent: 40,
                                        ),
                                        // Description
                                        if (description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.indigo[50],
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(
                                                  Icons.short_text,
                                                  color: Colors.indigo,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  description,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if ((journal['activities'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.amber[50],
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(
                                                  Icons.local_activity,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: (journal['activities'] as List<dynamic>?)
                                                          ?.map(
                                                            (activity) => Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: Colors.white.withOpacity(0.7),
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(
                                                                  color: Colors.amber.withOpacity(0.3),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    _getActivityIcon(activity.toString()),
                                                                    size: 14,
                                                                    color: Colors.amber[700],
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    activity.toString(),
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Colors.amber[900],
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          )
                                                          .toList() ??
                                                      [],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        // Note
                                        if (note.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.lightBlue[50],
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(
                                                  Icons.notes,
                                                  color: Colors.lightBlue,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  note,
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const Spacer(),
                                        // Page indicator
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.teal[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Page ${index + 1} of ${journals.length}',
                                              style: TextStyle(
                                                color: Colors.teal[400],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
                  // Animated Dots Indicator
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(journals.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.teal[400]
                                : Colors.cyan[200],
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: _currentPage == i
                                ? [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.18),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
