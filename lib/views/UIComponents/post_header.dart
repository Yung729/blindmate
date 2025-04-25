
import 'package:flutter/material.dart';
import '../UIComponents/post_privacy_indicator.dart';

class PostHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl; // Now nullable, can be null or empty
  final String timeAgo;
  final bool isPublic;
  final VoidCallback? onOptions;
  final bool isTripJournal;
  final VoidCallback? onTripJournalTap;
  final String defaultAsset;

  const PostHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.timeAgo,
    required this.isPublic,
    this.onOptions,
    this.isTripJournal = false,
    this.onTripJournalTap,
    this.defaultAsset = 'assets/default_pic.jpg',
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider avatarProvider;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarProvider = NetworkImage(avatarUrl!);
    } else {
      avatarProvider = AssetImage(defaultAsset);
    }

    return Row(
      children: [
        CircleAvatar(
          backgroundImage: avatarProvider,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    timeAgo,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 5),
                  PostPrivacyIndicator(
                    privacy: isPublic ? 'public' : 'private',
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onOptions != null)
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onOptions,
          ),
      ],
    );
  }
}
