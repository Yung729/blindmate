import 'package:flutter/material.dart';
import 'trip_journal_panel.dart';
import 'custom_button.dart';

const LinearGradient _journalGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF43B1F4), Color(0xFF1E88E5)],
);

const Map<String, IconData> availableActivities = {
  'Food & Dining': Icons.restaurant,
  'Sunset View': Icons.wb_sunny,
  'Swimming': Icons.pool,
  'Beach': Icons.beach_access,
  'Hiking': Icons.hiking,
  'Shopping': Icons.shopping_bag,
  'Sightseeing': Icons.photo_camera,
  'Water Sports': Icons.surfing,
  'Nature': Icons.park,
  'Cultural': Icons.museum,
};

class TripJournalEntry {
  TextEditingController locationController;
  TextEditingController descriptionController;
  DateTime? date;
  Set<String> activities;

  TripJournalEntry({
    String? initialLocation,
    String? initialDescription,
    DateTime? initialDate,
    Set<String>? initialActivities,
  }) : locationController = TextEditingController(text: initialLocation ?? ''),
       descriptionController = TextEditingController(
         text: initialDescription ?? '',
       ),
       date = initialDate,
       activities = initialActivities ?? {};
}

class TripJournalDialog extends StatefulWidget {
  final List<Map<String, dynamic>>? initialEntries;
  final Function(List<Map<String, dynamic>> entries) onJournalsAdded;
  final List<Map<String, dynamic>> pastJournals;
  final String actionButtonText;

  const TripJournalDialog({
    Key? key,
    this.initialEntries,
    required this.onJournalsAdded,
    required this.pastJournals,
    this.actionButtonText = 'Save Journal',
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    List<Map<String, dynamic>>? initialEntries,
    required Function(List<Map<String, dynamic>> entries) onJournalsAdded,
    required List<Map<String, dynamic>> pastJournals,
    String actionButtonText = 'Save Journal',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TripJournalDialog(
            initialEntries: initialEntries,
            onJournalsAdded: onJournalsAdded,
            pastJournals: pastJournals,
            actionButtonText: actionButtonText,
          ),
        );
      },
    );
  }

  @override
  State<TripJournalDialog> createState() => _TripJournalDialogState();
}

class _TripJournalDialogState extends State<TripJournalDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<TripJournalEntry> _entries;
  static const int maxEntries = 7;

  late List<bool> _dateErrors;

  bool _canAddMoreDays() {
    if (_entries.isEmpty) return false;
    return _entries.last.date != null;
  }

  @override
  void initState() {
    super.initState();
    _entries =
        (widget.initialEntries != null && widget.initialEntries!.isNotEmpty)
            ? widget.initialEntries!
                .map(
                  (e) => TripJournalEntry(
                    initialLocation: e['location'] as String?,
                    initialDescription: e['description'] as String?,
                    initialDate: e['date'] as DateTime?,
                    initialActivities:
                        (e['activities'] as List<dynamic>?)
                            ?.map((a) => a.toString())
                            .toSet() ??
                        <String>{},
                  ),
                )
                .toList()
            : [TripJournalEntry(initialActivities: <String>{})];

    // Initialize date errors
    _dateErrors = List.generate(_entries.length, (index) => false);
  }

  void _showPastJournals() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TripJournalPanel(
            posts: widget.pastJournals,
            getTimeAgo: (date) => '${date.day}/${date.month}/${date.year}',
            onViewTripJournal: (context, post) {
              Navigator.pop(context);
              Navigator.pop(context);
              if ((post['tripJournals']?.isNotEmpty ?? false)) {
                widget.onJournalsAdded(
                  List<Map<String, dynamic>>.from(post['tripJournals']),
                );
              }
            },
            onClose: () => Navigator.pop(context),
            isSelectionMode: true,
            onSelect: (post) {
              Navigator.pop(context);
              if ((post['tripJournals']?.isNotEmpty ?? false)) {
                widget.onJournalsAdded(
                  List<Map<String, dynamic>>.from(post['tripJournals']),
                );
              }
            },
            title: 'Select Past Journal',
          ),
    );
  }

  void _pickDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entries[index].date ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _entries[index].date = picked;
        _dateErrors[index] = false; // Clear error if date picke
        if (index == 0) {
          // Update all subsequent dates
          for (int i = 1; i < _entries.length; i++) {
            _entries[i].date = picked.add(Duration(days: i));
            _dateErrors[i] = false; // Clear errors for subsequent days
          }
        }
      });
    }
  }

  void _handleAdd() {
    final formValid = _formKey.currentState!.validate();
    bool allDatesValid = true;
    setState(() {
      // Validate dates
      for (int i = 0; i < _entries.length; i++) {
        if (_entries[i].date == null) {
          _dateErrors[i] = true;
          allDatesValid = false;
        } else {
          _dateErrors[i] = false;
        }
      }
    });

    if (formValid && allDatesValid) {
      final result =
          _entries
              .map(
                (e) => {
                  'location': e.locationController.text,
                  'description': e.descriptionController.text,
                  'date': e.date,
                  'activities': e.activities.toList(),
                },
              )
              .toList();
      widget.onJournalsAdded(result);
      Navigator.pop(context);
    }
  }

  void _addEntry() {
    if (_entries.length < maxEntries && _canAddMoreDays()) {
      setState(() {
        final lastDate = _entries.last.date!;
        final nextDate = lastDate.add(const Duration(days: 1));
        _entries.add(
          TripJournalEntry(
            initialActivities: <String>{},
            initialDate: nextDate,
          ),
        );
        _dateErrors.add(false); // Add error flag for new entry
      });
    }
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _dateErrors.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.locationController.dispose();
      entry.descriptionController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient Header
                Container(
                  decoration: BoxDecoration(
                    gradient: _journalGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Trip Journal",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              // Add this IconButton for past journals
                              IconButton(
                                icon: const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: _showPastJournals,
                                tooltip: 'Past Journals',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 28,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: 80, // Added padding for floating buttons
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _entries.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                return _buildJournalEntry(entry, index);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Action Buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Add More Days',
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed:
                          (_entries.length >= maxEntries || !_canAddMoreDays())
                              ? null
                              : _addEntry,
                      backgroundColor:
                          _canAddMoreDays()
                              ? Colors.blue.shade700
                              : Colors.grey.shade400,
                      fontSize: 15,
                      borderRadius: 30,
                      verticalPadding: 15,
                      horizontalPadding: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: widget.actionButtonText,
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      onPressed: _handleAdd,
                      backgroundColor: Colors.green.shade600,
                      fontSize: 15,
                      borderRadius: 30,
                      verticalPadding: 15,
                      horizontalPadding: 0,
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

  Widget _buildJournalEntry(TripJournalEntry entry, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  "Day ${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_entries.length > 1) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                    ),
                    onPressed: () => _removeEntry(index),
                  ),
                ],
              ],
            ),
          ),
          // Entry Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Field
                TextFormField(
                  controller: entry.locationController,
                  decoration: InputDecoration(
                    labelText: "Location",
                    hintText: "Enter location",
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator:
                      (value) =>
                          value?.trim().isEmpty == true
                              ? 'Location is required'
                              : null,
                ),
                const SizedBox(height: 16),
                // Description Field
                TextFormField(
                  controller: entry.descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: "Add a short description (optional)",
                    prefixIcon: const Icon(
                      Icons.description,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                // Activities Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_activity,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Activities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            availableActivities.entries.map((activity) {
                              final isSelected = entry.activities.contains(
                                activity.key,
                              );
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      activity.value,
                                      size: 16,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      activity.key,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      entry.activities.add(activity.key);
                                    } else {
                                      entry.activities.remove(activity.key);
                                    }
                                  });
                                },
                                selectedColor: Colors.blue.shade600,
                                backgroundColor: Colors.blue.shade50,
                                checkmarkColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Colors.transparent
                                            : Colors.blue.shade200,
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Date Picker
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          _dateErrors[index]
                              ? Colors.red
                              : Colors.blue.shade200,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.date == null
                              ? 'Select Date'
                              : '${entry.date!.day}/${entry.date!.month}/${entry.date!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                entry.date == null
                                    ? Colors.grey
                                    : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (index == 0)
                        TextButton(
                          onPressed: () => _pickDate(index),
                          child: Text(
                            'Choose',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.lock,
                              color: Colors.blue.shade200,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: TextStyle(
                                color: Colors.blue.shade200,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_dateErrors[index])
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 4.0),
                    child: Text(
                      'Date is required',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
