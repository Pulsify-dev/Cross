import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../routes/route_names.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final track = player.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).pushNamed(RouteNames.trackDetails, arguments: track);
          },
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                  const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: track.artworkUrl ?? '',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artistName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    player.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                  onPressed: () {
                    if (player.isPlaying) {
                      player.pause();
                    } else {
                      player.resume();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
