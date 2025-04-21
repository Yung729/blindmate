
import 'package:flutter/material.dart';
import '../UIComponents/post_privacy_indicator.dart';

class PostHeader extends StatelessWidget {
  final String userName;
  final String avatarAsset;
  final String timeAgo;
  final bool isPublic;
  final VoidCallback? onOptions; // Now nullable
  final bool isTripJournal;
  final VoidCallback? onTripJournalTap;

  const PostHeader({
    super.key,
    required this.userName,
    required this.avatarAsset,
    required this.timeAgo,
    required this.isPublic,
    this.onOptions, // Now optional
    this.isTripJournal = false,
    this.onTripJournalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(avatarAsset),
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
                  if (isTripJournal)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: InkWell(
                        onTap: onTripJournalTap,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Only show the options button if onOptions is not null
        if (onOptions != null)
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onOptions,
          ),
      ],
    );
  }
}
