import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'fetch_url_thumbail.dart';

class PostUrlPreview extends StatefulWidget {
  final String linkUrl;

  const PostUrlPreview({
    Key? key,
    required this.linkUrl,
  }) : super(key: key);

  @override
  State<PostUrlPreview> createState() => _PostUrlPreviewState();
}

class _PostUrlPreviewState extends State<PostUrlPreview> {
  // Static cache for all instances
  static final Map<String, Map<String, String>> _cache = {};
  Map<String, String>? _metadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    if (_cache.containsKey(widget.linkUrl)) {
      setState(() {
        _metadata = _cache[widget.linkUrl];
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await fetchUrlMetadata(widget.linkUrl);
      if (data != null) {
        _cache[widget.linkUrl] = data;
        if (mounted) {
          setState(() {
            _metadata = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading URL preview: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_metadata == null) {
      return const SizedBox.shrink();
    }

    final thumbnailUrl = _metadata!['image'];
    final title = _metadata!['title'];
    final description = _metadata!['description'];

    return GestureDetector(
      onTap: () async {
        final Uri url = Uri.parse(widget.linkUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  thumbnailUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}