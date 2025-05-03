
import 'package:flutter/material.dart';
import '../../viewmodels/uiValidation/url_validator.dart'; // Import the URL validation utility

class UrlInputDialog extends StatefulWidget {
  final Function(String url, String? thumbnail) onUrlAdded;

  const UrlInputDialog({
    super.key,
    required this.onUrlAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String url, String? thumbnail) onUrlAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: UrlInputDialog(
            onUrlAdded: onUrlAdded,
          ),
        );
      },
    );
  }

  @override
  UrlInputDialogState createState() => UrlInputDialogState();
}

class UrlInputDialogState extends State<UrlInputDialog> {
  final TextEditingController _urlController = TextEditingController();
  String? _thumbnailUrl;
  bool _isFetching = false;
  String? _errorText; // For error message

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleAddUrl() {
    final url = _urlController.text.trim();
    if (!UrlUtils.isValidUrl(url)) {
      setState(() {
        _errorText = "Please enter a valid URL (http/https).";
      });
      return;
    }
    widget.onUrlAdded(url, _thumbnailUrl);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add URL",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          // URL input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: "Enter URL...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.link, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _handleAddUrl,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorText: _errorText,
              ),
              autofocus: true,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
              onSubmitted: (_) => _handleAddUrl(),
            ),
          ),
          const SizedBox(height: 12),
          // Loading indicator or thumbnail preview
          if (_isFetching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_thumbnailUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Image.network(
                    _thumbnailUrl!,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Thumbnail preview",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
