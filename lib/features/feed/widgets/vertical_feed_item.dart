import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../../../providers/player_provider.dart';
import '../../../utils/number_formatter.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/auth_provider.dart';

class VerticalFeedItem extends StatelessWidget {
  final Track track;
  final VoidCallback? onPlay;
  final VoidCallback? onDetails;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onRepostToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onFollowTap;

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
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Artwork
        CachedNetworkImage(
          imageUrl: track.artworkUrl ?? '',
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

        // Action Buttons (Right Side)
        Positioned(
          right: 12,
          bottom: 120,
          child: Consumer<FeedProvider>(
            builder: (context, feedProvider, child) {
              final isLiked = feedProvider.isTrackLiked(track.id);
              final likeCount = feedProvider.getTrackLikeCount(track);
              final isReposted = feedProvider.isTrackReposted(track.id);
              final repostCount = feedProvider.getTrackRepostCount(track);

              return Column(
                children: [
                  _ActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: NumberFormatter.format(likeCount),
                    color: isLiked ? Colors.red : Colors.white,
                    onTap: onLikeToggle,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: NumberFormatter.format(track.commentCount),
                    onTap: onCommentTap,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.repeat,
                    label: NumberFormatter.format(repostCount),
                    color: isReposted ? Colors.green : Colors.white,
                    onTap: onRepostToggle,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.add_box_outlined,
                    label: 'Add',
                    onTap: onAddTap,
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
                        '${track.artistName} - ${track.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: track.uploader?.profileImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          track.uploader!.profileImageUrl!,
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
                          Text(
                            track.artistName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Consumer2<FeedProvider, AuthProvider>(
                            builder: (context, feedProvider, authProvider, child) {
                              final currentUserId = authProvider.currentUser?.id;
                              final targetId = track.uploader?.id ?? track.artistId;

                              // Don't show follow button if it's the current user's own track
                              if (targetId != null && targetId == currentUserId) {
                                return const SizedBox.shrink();
                              }

                              final isFollowing = targetId != null &&
                                  feedProvider.isFollowingUser(targetId);
                              return GestureDetector(
                                onTap: onFollowTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFollowing
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(15),
                                    border: isFollowing
                                        ? Border.all(color: Colors.white24)
                                        : null,
                                  ),
                                  child: Text(
                                    isFollowing ? 'Following' : 'Follow',
                                    style: TextStyle(
                                      color: isFollowing
                                          ? Colors.white70
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Play Button with Progress
                Consumer<PlayerProvider>(
                  builder: (context, player, child) {
                    final isCurrent = player.currentTrack?.id == track.id;
                    final isPlaying = isCurrent && player.isPlaying;
                    final progress = isCurrent
                        ? player.position.inMilliseconds /
                              (player.duration.inMilliseconds > 0
                                  ? player.duration.inMilliseconds
                                  : 1)
                        : 0.0;

                    return GestureDetector(
                      onTap: onPlay,
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
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
