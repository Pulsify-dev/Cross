import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../../../providers/player_provider.dart';
import '../../../utils/number_formatter.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/route_names.dart';

class VerticalFeedItem extends StatefulWidget {
  final Track track;
  final VoidCallback? onPlay;
  final VoidCallback? onDetails;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onRepostToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onFollowTap;
  final bool isActive;

  const VerticalFeedItem({
    super.key,
    required this.track,
    this.onPlay,
    this.onDetails,
    this.onLikeToggle,
    this.onRepostToggle,
    this.onCommentTap,
    this.onAddTap,
    this.onFollowTap,
    this.isActive = false,
  });

  @override
  State<VerticalFeedItem> createState() => _VerticalFeedItemState();
}

class _VerticalFeedItemState extends State<VerticalFeedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _overlayController;
  late Animation<double> _overlayOpacity;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _overlayOpacity = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  void _handleTapToToggle() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final isCurrent = player.currentTrack?.id == widget.track.id;

    if (isCurrent && player.isPlaying) {
      player.pause();
      _overlayController.forward();
    } else if (isCurrent && !player.isPlaying) {
      player.resume();
      _overlayController.reverse();
    } else {
      widget.onPlay?.call();
      _overlayController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Artwork
        CachedNetworkImage(
          imageUrl: widget.track.artworkUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black),
          errorWidget: (context, url, error) => Container(
            color: Colors.black,
            child: const Icon(Icons.music_note, size: 100, color: Colors.grey),
          ),
        ),

        // Gradient overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),

        // Tap to play/pause (full area, lowest priority)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _handleTapToToggle,
          ),
        ),

        // Pause overlay ("Tap to preview" + mute icon)
        _buildPauseOverlay(),

        // Action Buttons (Right Side)
        Positioned(
          right: 12,
          bottom: 140,
          child: Consumer<FeedProvider>(
            builder: (context, feedProvider, child) {
              final isLiked = feedProvider.isTrackLiked(widget.track.id);
              final likeCount = feedProvider.getTrackLikeCount(widget.track);
              final isReposted = feedProvider.isTrackReposted(widget.track.id);
              final repostCount =
                  feedProvider.getTrackRepostCount(widget.track);

              return Column(
                children: [
                  _ActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: NumberFormatter.format(likeCount),
                    color: isLiked ? Colors.red : Colors.white,
                    onTap: widget.onLikeToggle,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: NumberFormatter.format(widget.track.commentCount),
                    onTap: widget.onCommentTap,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.repeat,
                    label: NumberFormatter.format(repostCount),
                    color: isReposted ? Colors.green : Colors.white,
                    onTap: widget.onRepostToggle,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.add_box_outlined,
                    label: 'Add',
                    onTap: widget.onAddTap,
                  ),
                ],
              );
            },
          ),
        ),

        // Bottom Info Area
        Positioned(
          left: 12,
          right: 12,
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.track.artistName} - ${widget.track.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Artist avatar + name + follow button
                      _buildArtistRow(),
                    ],
                  ),
                ),

                // Play Button with Progress (tap ring → track details)
                Consumer<PlayerProvider>(
                  builder: (context, player, child) {
                    final isCurrent =
                        player.currentTrack?.id == widget.track.id;
                    final isPlaying = isCurrent && player.isPlaying;
                    final progress = isCurrent
                        ? player.position.inMilliseconds /
                              (player.duration.inMilliseconds > 0
                                  ? player.duration.inMilliseconds
                                  : 1)
                        : 0.0;

                    return GestureDetector(
                      onTap: () {
                        // Tap on progress ring → go to track details
                        Navigator.of(context).pushNamed(
                          RouteNames.trackDetails,
                          arguments: widget.track,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              value: isCurrent
                                  ? (progress.isNaN ? 0.0 : progress)
                                  : 0.0,
                              strokeWidth: 3.5,
                              backgroundColor: Colors.white12,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF5500),
                              ), // SoundCloud orange
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white12,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPauseOverlay() {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final isCurrent = player.currentTrack?.id == widget.track.id;
        final isPaused = isCurrent && !player.isPlaying;

        // Sync overlay animation with player state
        if (isPaused && widget.isActive) {
          _overlayController.forward();
        } else {
          _overlayController.reverse();
        }

        return FadeTransition(
          opacity: _overlayOpacity,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_off_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to preview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistRow() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: ClipOval(
            child: widget.track.uploader?.profileImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.track.uploader!.profileImageUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.track.artistName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        // Follow button with relationship state (blocked/mutual)
        Consumer2<FeedProvider, AuthProvider>(
          builder: (context, feedProvider, authProvider, child) {
            final currentUserId = authProvider.currentUser?.id;
            final targetId =
                widget.track.uploader?.id ?? widget.track.artistId;

            // Don't show for own tracks
            if (targetId != null && targetId == currentUserId) {
              return const SizedBox.shrink();
            }

            if (targetId == null) return const SizedBox.shrink();

            // If blocked by either side, hide the follow button
            if (feedProvider.isUserBlocked(targetId)) {
              return const SizedBox.shrink();
            }

            final isFollowing = feedProvider.isFollowingUser(targetId);
            final isMutual = feedProvider.isUserMutual(targetId);

            return GestureDetector(
              onTap: widget.onFollowTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isMutual
                      ? const Color(0xFFFF5500).withValues(alpha: 0.15)
                      : isFollowing
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isMutual
                        ? const Color(0xFFFF5500).withValues(alpha: 0.4)
                        : isFollowing
                            ? Colors.white24
                            : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMutual) ...[
                      Icon(
                        Icons.people_rounded,
                        color: const Color(0xFFFF5500),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isMutual
                          ? 'Friends'
                          : isFollowing
                              ? 'Following'
                              : 'Follow',
                      style: TextStyle(
                        color: isMutual
                            ? const Color(0xFFFF5500)
                            : isFollowing
                                ? Colors.white70
                                : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 32),
          onPressed: onTap,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
