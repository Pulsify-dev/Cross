import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../feed/models/track.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/feed_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/number_formatter.dart';
import '../widgets/scrolling_waveform_widget.dart';
import '../../../providers/engagement_provider.dart';
import '../../feed/services/track_service.dart';

class TrackDetailsScreen extends StatefulWidget {
  final Track track;
  final List<Track>? playlist;
  final bool isFeedMode;

  const TrackDetailsScreen({
    super.key,
    required this.track,
    this.playlist,
    this.isFeedMode = false,
  });

  @override
  State<TrackDetailsScreen> createState() => _TrackDetailsScreenState();
}

class _TrackDetailsScreenState extends State<TrackDetailsScreen>
    with TickerProviderStateMixin {
  bool _followingPlayer = false;
  bool _controlsVisible = false;
  bool _showLyrics = false;
  Timer? _hideTimer;
  String? _lyrics;
  bool _isLoadingLyrics = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Swipe state
  late AnimationController _swipeAnimController;
  double _dragOffset = 0.0;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      final feed = Provider.of<FeedProvider>(context, listen: false);

      player.loadWaveform(widget.track.id);
      feed.checkIfLiked(widget.track);
      feed.checkIfReposted(widget.track);
      context.read<EngagementProvider>().fetchComments(widget.track.id);

      if (player.currentTrack?.id == widget.track.id) {
        setState(() => _followingPlayer = true);
        if (widget.playlist != null) {
          player.setQueue(widget.playlist!, widget.track);
        }
        player.setFeedMode(widget.isFeedMode);
        if (!player.isPlaying) {
          player.resume();
        }
      } else {
        player.playTrack(
          widget.track,
          playlist: widget.playlist,
          isFeedMode: widget.isFeedMode,
        );
      }
      _startHideTimer();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    _swipeAnimController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    if (!_controlsVisible) {
      // Showing controls: Pause if playing
      setState(() => _controlsVisible = true);
      if (player.isPlaying) {
        player.pause();
      }
      _startHideTimer();
    } else {
      // Hiding controls: Resume if paused
      setState(() => _controlsVisible = false);
      if (!player.isPlaying) {
        player.resume();
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final player = Provider.of<PlayerProvider>(context, listen: false);
        // Only auto-hide if currently playing
        if (player.isPlaying) {
          setState(() => _controlsVisible = false);
        }
      }
    });
  }

  // ── Swipe gesture handlers ──

  void _onSwipeDragStart(DragStartDetails details) {
    if (_swipeAnimController.isAnimating) return;
    _isSwiping = true;
    _dragOffset = 0.0;
  }

  void _onSwipeDragUpdate(DragUpdateDetails details) {
    if (!_isSwiping) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final delta = details.primaryDelta ?? 0.0;

    // Rubber-band effect when no track in that direction
    if (_dragOffset + delta > 0 && !player.hasPreviousTrack) {
      setState(() => _dragOffset += delta * 0.15);
    } else if (_dragOffset + delta < 0 && !player.hasNextTrack) {
      setState(() => _dragOffset += delta * 0.15);
    } else {
      setState(() => _dragOffset += delta);
    }
  }

  void _onSwipeDragEnd(DragEndDetails details) {
    if (!_isSwiping) return;
    _isSwiping = false;

    final player = Provider.of<PlayerProvider>(context, listen: false);
    final velocity = details.primaryVelocity ?? 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.25;

    // Swipe left → next track
    if ((_dragOffset < -threshold || velocity < -800) && player.hasNextTrack) {
      _animateSwipeOff(-screenWidth, () {
        player.nextTrack();
        _startHideTimer();
      });
      return;
    }

    // Swipe right → previous track
    if ((_dragOffset > threshold || velocity > 800) &&
        player.hasPreviousTrack) {
      _animateSwipeOff(screenWidth, () {
        player.previousTrack();
        _startHideTimer();
      });
      return;
    }

    // Snap back
    _animateSnapBack();
  }

  void _animateSwipeOff(double targetX, VoidCallback onComplete) {
    final startOffset = _dragOffset;
    late Animation<double> anim;
    anim = Tween<double>(begin: startOffset, end: targetX).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeInOut),
    );

    void listener() {
      if (mounted) setState(() => _dragOffset = anim.value);
    }

    anim.addListener(listener);
    _swipeAnimController.forward(from: 0.0).then((_) {
      anim.removeListener(listener);
      onComplete();
      if (mounted) setState(() => _dragOffset = 0.0);
    });
  }

  void _animateSnapBack() {
    final startOffset = _dragOffset;
    late Animation<double> anim;
    anim = Tween<double>(begin: startOffset, end: 0.0).animate(
      CurvedAnimation(parent: _swipeAnimController, curve: Curves.easeOutCubic),
    );

    void listener() {
      if (mounted) setState(() => _dragOffset = anim.value);
    }

    anim.addListener(listener);
    _swipeAnimController.forward(from: 0.0).then((_) {
      anim.removeListener(listener);
    });
  }

  Future<void> _fetchLyrics() async {
    if (_lyrics != null || _isLoadingLyrics) return;
    setState(() => _isLoadingLyrics = true);
    try {
      final service = Provider.of<TrackService>(context, listen: false);
      final fetched = await service.getTrackLyrics(widget.track.id);
      if (mounted) {
        setState(() {
          _lyrics = fetched ?? 'No lyrics available for this track.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lyrics = 'Failed to load lyrics.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLyrics = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
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

          final waveform = player.getWaveform(displayTrack.id);

          // Swipe visual feedback
          final swipeOpacity =
              (1.0 -
                      (_dragOffset.abs() / MediaQuery.of(context).size.width) *
                          0.4)
                  .clamp(0.6, 1.0);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onHorizontalDragStart: _onSwipeDragStart,
              onHorizontalDragUpdate: _onSwipeDragUpdate,
              onHorizontalDragEnd: _onSwipeDragEnd,
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Opacity(
                  opacity: swipeOpacity,
                  child: Stack(
                    children: [
                      // Tappable artwork background
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleControls,
                          child: Hero(
                            tag: 'track_${displayTrack.id}',
                            child: _buildArtwork(displayTrack),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 180,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: screenHeight * 0.55,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black,
                                Colors.black.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.35, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Lyrics View
                      if (_showLyrics)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _toggleControls,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.85),
                              padding: EdgeInsets.only(
                                top: 160,
                                bottom: screenHeight * 0.4,
                                left: 24,
                                right: 24,
                              ),
                              child: _isLoadingLyrics
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : SingleChildScrollView(
                                      child: Text(
                                        _lyrics ??
                                            'No lyrics available for this track.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                      // Controls overlay (centered on artwork)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _controlsVisible || !isPlaying ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: IgnorePointer(
                            ignoring: !_controlsVisible && isPlaying,
                            child: GestureDetector(
                              onTap: _toggleControls,
                              child: Container(
                                color: Colors.black.withValues(
                                  alpha: _controlsVisible || !isPlaying
                                      ? 0.4
                                      : 0.0,
                                ),
                                child: Center(
                                  child: _buildPlayControls(
                                    player,
                                    displayTrack,
                                    isPlaying,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom content (always visible)
                      SafeArea(
                        child: Column(
                          children: [
                            _buildTopBar(displayTrack),

                            const Spacer(),

                            // Waveform or Progress Line
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Waveform (hidden when controls are visible)
                                AnimatedOpacity(
                                  opacity: _controlsVisible || !isPlaying
                                      ? 0.0
                                      : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: _buildWaveform(
                                    player,
                                    displayTrack,
                                    waveform,
                                  ),
                                ),
                                // Progress Line (shown when controls are visible)
                                if (_controlsVisible || !isPlaying)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      height: 2,
                                      width: double.infinity,
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor:
                                            (player.position.inMilliseconds /
                                                    (player
                                                                .duration
                                                                .inMilliseconds >
                                                            0
                                                        ? player
                                                              .duration
                                                              .inMilliseconds
                                                        : 1))
                                                .clamp(0.0, 1.0),
                                        child: Container(color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildTimePill(player, displayTrack),
                            ),

                            const SizedBox(height: 24),
                            _buildCommentBar(displayTrack),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.08),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildBottomBar(displayTrack),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtwork(Track track) {
    if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: track.artworkUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _artworkPlaceholder(),
      );
    }
    return _artworkPlaceholder();
  }

  Widget _artworkPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 100,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildTopBar(Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track title & artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artistName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // "Behind this track" and "Lyrics" buttons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Behind this track',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showLyrics = !_showLyrics;
                        });
                        if (_showLyrics) {
                          _fetchLyrics();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _showLyrics
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lyrics_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Lyrics',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Down chevron to close
          _circleButton(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 38,
            iconSize: 28,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 36,
    double iconSize = 22,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildWaveform(
    PlayerProvider player,
    Track track,
    List<double>? waveform,
  ) {
    if (waveform != null) {
      return ScrollingWaveformWidget(
        waveform: waveform,
        progress: player.currentTrack?.id == track.id
            ? (player.position.inMilliseconds / player.duration.inMilliseconds)
                  .clamp(0.0, 1.0)
            : 0.0,
        height: 70,
        color: Colors.white.withValues(alpha: 0.25),
        progressColor: Theme.of(context).colorScheme.primary,
        playheadColor: Theme.of(context).colorScheme.primary,
        barWidth: 3.0,
        barGap: 1.5,
        onSeek: (percent) {
          if (player.currentTrack?.id == track.id) {
            final seekMs = (percent * player.duration.inMilliseconds).round();
            player.seek(Duration(milliseconds: seekMs));
          } else {
            player.playTrack(track).then((_) {
              final seekMs = (percent * track.duration.inMilliseconds).round();
              player.seek(Duration(milliseconds: seekMs));
            });
          }
        },
      );
    }
    return const SizedBox(
      height: 70,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildTimePill(PlayerProvider player, Track track) {
    final position = player.currentTrack?.id == track.id
        ? player.position
        : Duration.zero;
    final duration = player.currentTrack?.id == track.id
        ? player.duration
        : track.duration;

    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${_formatDuration(position)}  |  ${_formatDuration(duration)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayControls(
    PlayerProvider player,
    Track track,
    bool isPlaying,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip previous
        GestureDetector(
          key: const Key('player_skip_prev_button'),
          onTap: () {
            player.previousTrack();
            _startHideTimer();
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.7),
            ),
            child: const Icon(
              Icons.skip_previous_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Play / Pause
        GestureDetector(
          key: const Key('player_play_pause_button'),
          onTap: () {
            if (player.currentTrack?.id == track.id) {
              if (isPlaying) {
                player.pause();
              } else {
                player.resume();
                _startHideTimer();
              }
            } else {
              player.playTrack(track);
              _startHideTimer();
            }
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.7),
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Skip next
        GestureDetector(
          key: const Key('player_skip_next_button'),
          onTap: () {
            player.nextTrack();
            _startHideTimer();
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.7),
            ),
            child: const Icon(
              Icons.skip_next_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBar(Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, '/comments', arguments: track),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.mode_comment_outlined,
                color: Colors.white.withValues(alpha: 0.4),
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Comment...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(Track track) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomAction(
                icon: track.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: NumberFormatter.format(track.likeCount),
                isActive: track.isLiked,
                activeColor: Theme.of(context).colorScheme.primary,
                onTap: () => feedProvider.toggleLike(track),
              ),

              Consumer<EngagementProvider>(
                builder: (context, engagementProvider, _) {
                  final count = engagementProvider.commentsCount > 0
                      ? engagementProvider.commentsCount
                      : track.commentCount;
                  return _BottomAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: NumberFormatter.format(count),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/comments',
                      arguments: track,
                    ),
                  );
                },
              ),

              _BottomAction(
                icon: track.isReposted
                    ? Icons.repeat_on_rounded
                    : Icons.repeat_rounded,
                label: NumberFormatter.format(track.repostCount),
                isActive: track.isReposted,
                activeColor: Theme.of(context).colorScheme.primary,
                onTap: () => feedProvider.toggleRepost(track),
              ),

              _BottomAction(
                icon: Icons.bar_chart_rounded,
                label: '',
                onTap: () => _showLikesAndReposts(context, track),
                tooltip: 'Likes & Reposts',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLikesAndReposts(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Engagement',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.favorite_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Likes', style: TextStyle(color: Colors.white)),
              trailing: Text(
                NumberFormatter.format(track.likeCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/likes', arguments: track);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.repeat_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Reposts',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Text(
                NumberFormatter.format(track.repostCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/reposts', arguments: track);
              },
            ),
          ],
        ),
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

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const _BottomAction({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? Colors.white)
        : Colors.white.withValues(alpha: 0.6);

    final child = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
