import 'package:flutter/material.dart';

class CreatePostDialog extends StatefulWidget {
  final void Function({
    required String content,
    String? musicUrl,
    String? musicTitle,
    String? location,
    DateTime? tripDate,
    required bool isTripJournal,
  }) onSubmit;

  const CreatePostDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  String _content = '';
  String? _musicUrl;
  String? _musicTitle;

  // Trip Journal fields
  String? _tripLocation;
  DateTime? _tripDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Post'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'What\'s on your mind?'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Enter content' : null,
                onChanged: (v) => _content = v,
              ),
              const SizedBox(height: 10),
              // Add Music Button
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.music_note),
                    label: const Text('Add Music'),
                    onPressed: () async {
                      // TODO: Implement your add music logic
                      // For demo, just set dummy values
                      setState(() {
                        _musicUrl = "https://music.example.com";
                        _musicTitle = "Sample Music";
                      });
                    },
                  ),
                  if (_musicTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _musicTitle!,
                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Add Trip Journal Button
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.location_on),
                    label: const Text('Trip Journal'),
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => _TripJournalFieldsDialog(
                          initialLocation: _tripLocation,
                          initialDate: _tripDate,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _tripLocation = result['location'];
                          _tripDate = result['tripDate'];
                        });
                      }
                    },
                  ),
                  if (_tripLocation != null && _tripDate != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        "${_tripLocation!} (${_tripDate!.day}/${_tripDate!.month}/${_tripDate!.year})",
                        style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit(
                content: _content,
                musicUrl: _musicUrl,
                musicTitle: _musicTitle,
                location: _tripLocation,
                tripDate: _tripDate,
                isTripJournal: _tripLocation != null && _tripDate != null,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Post'),
        ),
      ],
    );
  }
}

/// Dialog for entering Trip Journal fields
class _TripJournalFieldsDialog extends StatefulWidget {
  final String? initialLocation;
  final DateTime? initialDate;

  const _TripJournalFieldsDialog({this.initialLocation, this.initialDate});

  @override
  State<_TripJournalFieldsDialog> createState() => _TripJournalFieldsDialogState();
}

class _TripJournalFieldsDialogState extends State<_TripJournalFieldsDialog> {
  final _formKey = GlobalKey<FormState>();
  String _location = '';
  DateTime? _tripDate;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation ?? '';
    _tripDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trip Journal Details'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
              onChanged: (v) => _location = v,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tripDate == null
                        ? 'Select Date'
                        : '${_tripDate!.day}/${_tripDate!.month}/${_tripDate!.year}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _tripDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _tripDate = picked);
                    }
                  },
                  child: const Text('Pick Date'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _tripDate != null) {
              Navigator.pop(context, {
                'location': _location,
                'tripDate': _tripDate,
              });
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
