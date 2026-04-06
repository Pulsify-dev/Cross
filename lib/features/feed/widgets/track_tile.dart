import 'package:flutter/material.dart';
import '../models/track.dart';
import '../../../utils/number_formatter.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onPlay;
  final VoidCallback? onDetails;
  final VoidCallback? onLikeToggle;

  const TrackTile({
    super.key,
    required this.track,
    this.onPlay,
    this.onDetails,
    this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPlay,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.artworkUrl ?? '',
          width: 50,
          height: 50,
          fit: BoxFit.cover,

          
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 50,
              height: 50,
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },

          
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.music_note,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            );
          },
        ),
      ),
      title: Text(
        track.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artistName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            NumberFormatter.format(track.likeCount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 12,
                ),
          ),
          IconButton(
            icon: Icon(
              track.isLiked ? Icons.favorite : Icons.favorite_border,
              color: track.isLiked
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
            ),
            onPressed: onLikeToggle,
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            onPressed: onDetails,
          ),
        ],
      ),
    );
  }
}