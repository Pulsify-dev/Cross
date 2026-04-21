import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final track = player.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final progress = player.duration.inMilliseconds > 0
            ? player.position.inMilliseconds / player.duration.inMilliseconds
            : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(RouteNames.trackDetails, arguments: track);
          },
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.navBarBackground.withValues(alpha: 0.95),
              border: const Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // SoundCloud-style top progress bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 2,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Row(
                    children: [
                      // Artwork
                      Hero(
                        tag: 'player_artwork_${track.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: track.artworkUrl ?? '',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.music_note, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Track Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artistName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                               maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 28,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: () => player.previousTrack(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              size: 38,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: () {
                              if (player.isPlaying) {
                                player.pause();
                              } else {
                                player.resume();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              size: 28,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: () => player.nextTrack(),
                          ),
                        ],
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
}
