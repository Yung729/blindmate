import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:url_launcher/url_launcher.dart';


Future<Map<String, String>?> fetchUrlMetadata(String url) async {
  try {
    final metadata = await MetadataFetch.extract(url);
    if (metadata != null) {
      return {
        'title': metadata.title ?? "No title",
        'description': metadata.description ?? "No description available",
        'image': metadata.image ?? "",
        'url': url,
      };
    }
  } catch (e) {
    print("Error fetching metadata: $e");
  }
  return null;
}

Widget buildLinkPreview(String url) {
  return FutureBuilder<Map<String, String>?> (
    future: fetchUrlMetadata(url),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData) return Container();

      final metadata = snapshot.data!;
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(metadata['url']!)),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (metadata['image']!.isNotEmpty)
                Image.network(metadata['image']!, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata['description']!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
