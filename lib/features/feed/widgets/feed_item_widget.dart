import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import 'track_card.dart';

class FeedItemWidget extends StatelessWidget {
  final FeedItem item;
  final VoidCallback? onPlay;
  final VoidCallback? onDetails;
  final VoidCallback? onLikeToggle;

  const FeedItemWidget({
    super.key,
    required this.item,
    this.onPlay,
    this.onDetails,
    this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.type == 'repost' && item.repostedBy != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.repeat, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${item.repostedBy!.displayName} reposted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (item.track != null)
          TrackCard(
            track: item.track!,
            onPlay: onPlay,
            onDetails: onDetails,
            onLikeToggle: onLikeToggle,
          ),
      ],
    );
  }
}
