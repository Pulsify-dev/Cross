import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../utils/number_formatter.dart';
import '../models/track.dart';
import '../../feed/services/track_service.dart';

class TrackTile extends StatefulWidget {
  final Track track;
  final VoidCallback? onPlay;
  final VoidCallback? onDetails;
  final VoidCallback? onLikeToggle;
  final bool showLike;

  const TrackTile({
    super.key,
    required this.track,
    this.onPlay,
    this.onDetails,
    this.onLikeToggle,
    this.showLike = false,
  });

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  String? _artworkUrl;
  Track? _fetchedTrack;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _artworkUrl = widget.track.artworkUrl;
    _checkAndFetchDetails();
  }

  @override
  void didUpdateWidget(covariant TrackTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id || oldWidget.track.artworkUrl != widget.track.artworkUrl) {
      _artworkUrl = widget.track.artworkUrl;
      _fetchedTrack = null;
      _checkAndFetchDetails();
    }
  }

  void _checkAndFetchDetails() {
    // If artwork is empty or fallback avatar, or if we just want to refresh counts
    final uploaderAvatar = widget.track.uploader?.profileImageUrl;
    bool isFallback = uploaderAvatar != null && _artworkUrl != null && _artworkUrl!.contains(uploaderAvatar);
    
    if (_artworkUrl == null || _artworkUrl!.isEmpty || isFallback || _fetchedTrack == null) {
      _fetchFullTrackDetails();
    }
  }

  Future<void> _fetchFullTrackDetails() async {
    if (_isLoadingDetails) return;
    
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final trackService = context.read<TrackService>();
      final fullTrack = await trackService.getTrackById(widget.track.id);
      
      if (mounted && fullTrack != null) {
        // Update the original track object properties (since we made them non-final)
        // to ensure the changes propagate to other screens using this object.
        widget.track.artworkUrl = fullTrack.artworkUrl;
        widget.track.likeCount = fullTrack.likeCount;
        widget.track.commentCount = fullTrack.commentCount;
        widget.track.repostCount = fullTrack.repostCount;
        widget.track.isLiked = fullTrack.isLiked;
        widget.track.isReposted = fullTrack.isReposted;
        if (fullTrack.artistName != 'Unknown Artist') {
          widget.track.artistName = fullTrack.artistName;
        }

        setState(() {
          _fetchedTrack = fullTrack;
          _artworkUrl = fullTrack.artworkUrl;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch full track details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = _fetchedTrack ?? widget.track;
    
    return ListTile(
      onTap: widget.onPlay,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: (_artworkUrl != null && _artworkUrl!.isNotEmpty)
            ? Image.network(
                _artworkUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  );
                },
              )
            : Container(
                width: 50,
                height: 50,
                color: Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
      ),
      title: Text(
        currentTrack.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentTrack.artistName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (currentTrack.status != null && currentTrack.status != 'Finished')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                currentTrack.status!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          final isLiked = feedProvider.isTrackLiked(currentTrack.id);
          final likeCount = feedProvider.getTrackLikeCount(currentTrack);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showLike) ...[
                Text(
                  NumberFormatter.format(likeCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: widget.onLikeToggle,
                ),
              ],
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                onPressed: widget.onDetails,
              ),
            ],
          );
        },
      ),
    );
  }
}
