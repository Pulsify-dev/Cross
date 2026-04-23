import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../feed/models/track.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/feed_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/number_formatter.dart';
import '../widgets/waveform_widget.dart';

class TrackDetailsScreen extends StatefulWidget {
  final Track track;

  const TrackDetailsScreen({super.key, required this.track});

  @override
  State<TrackDetailsScreen> createState() => _TrackDetailsScreenState();
}

class _TrackDetailsScreenState extends State<TrackDetailsScreen> {
  bool _followingPlayer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      final feed = Provider.of<FeedProvider>(context, listen: false);
      
      player.loadWaveform(widget.track.id);
      feed.checkIfLiked(widget.track);
      feed.checkIfReposted(widget.track);
      
      if (player.currentTrack?.id == widget.track.id) {
        setState(() => _followingPlayer = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Consumer<PlayerProvider>(
        builder: (context, player, child) {
          if (!_followingPlayer && player.currentTrack?.id == widget.track.id) {
            _followingPlayer = true;
          }

          final displayTrack = _followingPlayer
              ? (player.currentTrack ?? widget.track)
              : widget.track;
          final isPlaying =
              player.currentTrack?.id == displayTrack.id && player.isPlaying;

          final status = player.currentTrack?.id == displayTrack.id
              ? player.currentStatus
              : null;
          final waveform = player.getWaveform(displayTrack.id);

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Spacer(),
                    Hero(
                      tag: 'track_${displayTrack.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: displayTrack.artworkUrl ?? '',
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: MediaQuery.of(context).size.width * 0.7,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (status != null && status['status'] != 'Finished')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Transcoding: ${status['progress_percent']}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      displayTrack.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayTrack.artistName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (waveform != null)
                      WaveformWidget(
                        waveform: waveform,
                        progress: player.currentTrack?.id == displayTrack.id
                            ? (player.position.inMilliseconds /
                                      player.duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                            : 0.0,
                        height: 80,
                        progressColor: Theme.of(context).colorScheme.primary,
                      )
                    else
                      const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(
                              player.currentTrack?.id == displayTrack.id
                                  ? player.position
                                  : Duration.zero,
                            ),
                          ),
                          Text(
                            _formatDuration(
                              player.currentTrack?.id == displayTrack.id
                                  ? player.duration
                                  : displayTrack.duration,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          key: const Key('player_skip_prev_button'),
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: () => player.previousTrack(),
                        ),
                        IconButton(
                          key: const Key('player_play_pause_button'),
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 80,
                          ),
                          onPressed: () {
                            if (player.currentTrack?.id == displayTrack.id) {
                              if (isPlaying) {
                                player.pause();
                              } else {
                                player.resume();
                              }
                            } else {
                              player.playTrack(displayTrack);
                            }
                          },
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        IconButton(
                          key: const Key('player_skip_next_button'),
                          icon: const Icon(Icons.skip_next, size: 36),
                          onPressed: () => player.nextTrack(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Consumer<FeedProvider>(
                      builder: (context, feedProvider, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                IconButton(
                                  key: const Key('player_comment_button'),
                                  icon: const Icon(Icons.comment_outlined),
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/comments',
                                    arguments: displayTrack,
                                  ),
                                  tooltip: 'Comments',
                                ),
                                Text(
                                  NumberFormatter.format(
                                    displayTrack.commentCount,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Column(
                              children: [
                                IconButton(
                                  key: const Key('player_like_button'),
                                  icon: Icon(
                                    displayTrack.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: displayTrack.isLiked
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                  onPressed: () =>
                                      feedProvider.toggleLike(displayTrack),
                                  tooltip: 'Like',
                                ),
                                Text(
                                  NumberFormatter.format(
                                    displayTrack.likeCount,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    displayTrack.isReposted
                                        ? Icons.repeat_on
                                        : Icons.repeat,
                                    color: displayTrack.isReposted
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                  onPressed: () =>
                                      feedProvider.toggleRepost(displayTrack),
                                  tooltip: 'Repost',
                                ),
                                Text(
                                  NumberFormatter.format(
                                    displayTrack.repostCount,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),
                            IconButton(
                              icon: const Icon(Icons.people_outline),
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/likes',
                                arguments: displayTrack,
                              ),
                              tooltip: 'Likers',
                            ),
                            IconButton(
                              icon: const Icon(Icons.groups_outlined),
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/reposts',
                                arguments: displayTrack,
                              ),
                              tooltip: 'Reposters',
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
