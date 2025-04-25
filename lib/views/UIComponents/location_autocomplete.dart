
import 'package:flutter/material.dart';
import '../../models/api/location_service.dart';

class NominatimLocationAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;

  const NominatimLocationAutocomplete({
    Key? key,
    required this.controller,
    this.hintText = "Search location",
  }) : super(key: key);

  @override
  State<NominatimLocationAutocomplete> createState() =>
      _NominatimLocationAutocompleteState();
}

class _NominatimLocationAutocompleteState
    extends State<NominatimLocationAutocomplete> {
  List<dynamic> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Triggers rebuild to show/hide clear button
  }

  Future<void> _search(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await LocationService.searchLocations(query);
    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.location_on, color: Colors.green),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _suggestions = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: _search,
        ),
        if (_isLoading) const LinearProgressIndicator(),
        if (_suggestions.isNotEmpty)
          Container(
            height: 200, // Fixed height for dropdown
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(suggestion['display_name']),
                  onTap: () {
                    widget.controller.text = suggestion['display_name'];
                    setState(() => _suggestions = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
