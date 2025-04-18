
import 'package:flutter/material.dart';

class TripJournalEntry {
  TextEditingController locationController;
  DateTime? date;

  TripJournalEntry({String? initialLocation, DateTime? initialDate})
      : locationController = TextEditingController(text: initialLocation ?? ''),
        date = initialDate;
}

class TripJournalDialog extends StatefulWidget {
  final List<Map<String, dynamic>>? initialEntries;
  final Function(List<Map<String, dynamic>> entries) onJournalsAdded;

  const TripJournalDialog({
    Key? key,
    this.initialEntries,
    required this.onJournalsAdded,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    List<Map<String, dynamic>>? initialEntries,
    required Function(List<Map<String, dynamic>> entries) onJournalsAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TripJournalDialog(
            initialEntries: initialEntries,
            onJournalsAdded: onJournalsAdded,
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

  @override
  void initState() {
    super.initState();
    _entries = (widget.initialEntries != null && widget.initialEntries!.isNotEmpty)
        ? widget.initialEntries!
            .map((e) => TripJournalEntry(
                  initialLocation: e['location'] as String?,
                  initialDate: e['date'] as DateTime?,
                ))
            .toList()
        : [TripJournalEntry()];
  }

  void _pickDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entries[index].date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _entries[index].date = picked);
    }
  }

  void _handleAdd() {
    if (_formKey.currentState!.validate() &&
        _entries.every((e) => e.date != null)) {
      final result = _entries
          .map((e) => {
                'location': e.locationController.text,
                'date': e.date,
              })
          .toList();
      widget.onJournalsAdded(result);
      Navigator.pop(context);
    }
  }

  void _addEntry() {
    setState(() {
      _entries.add(TripJournalEntry());
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.locationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Form(
            key: _formKey,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Trip Journal",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Entries
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Trip ${index + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_entries.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeEntry(index),
                                      ),
                                  ],
                                ),
                                TextFormField(
                                  controller: entry.locationController,
                                  decoration: InputDecoration(
                                    labelText: "Location",
                                    hintText: "E.g. Mount Fuji",
                                    prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.date == null
                                            ? 'Select Date'
                                            : '${entry.date!.day}/${entry.date!.month}/${entry.date!.year}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: entry.date == null ? Colors.grey : Colors.black,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _pickDate(index),
                                      icon: const Icon(Icons.calendar_today, size: 18),
                                      label: const Text('Pick Date'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Add More button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.green),
                          label: const Text("Add More"),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _addEntry,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add to Journal button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
                      label: const Text(
                        "Add to Journal",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      onPressed: _handleAdd,
                    ),
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
