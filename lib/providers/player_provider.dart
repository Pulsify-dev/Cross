import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:just_audio/just_audio.dart';
import '../features/feed/models/track.dart';
import '../features/feed/services/track_service.dart';

class PlayerProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final TrackService? _trackService;
  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final Map<String, List<double>> _waveformCache = {};
  Map<String, dynamic>? _currentStatus;

  void Function(Track track)? onTrackStarted;

  PlayerProvider({TrackService? trackService}) : _trackService = trackService {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  Future<void> _onTrackCompleted() async {
    final completedTrackId = _currentTrack?.id;
    final finalPosition = _position.inMilliseconds;

    // Immediately move to next track
    await nextTrack();

    // Record the play in the background
    if (completedTrackId != null) {
      _trackService?.recordPlay(
        completedTrackId,
        durationPlayedMs: finalPosition,
      );
    }
  }

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  List<Track> get queue => _queue;
  int get currentIndex => _currentIndex;

  List<double>? get currentWaveform =>
      _currentTrack != null ? _waveformCache[_currentTrack!.id] : null;
  List<double>? getWaveform(String trackId) => _waveformCache[trackId];

  Map<String, dynamic>? get currentStatus => _currentStatus;

  Future<void> loadWaveform(String trackId) async {
    if (_waveformCache.containsKey(trackId)) return;

    try {
      final wf = await _trackService?.getTrackWaveform(trackId);
      if (wf != null) {
        _waveformCache[trackId] = wf;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading waveform: $e');
    }
  }

  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    if (playlist != null) {
      _queue = playlist;
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
    } else if (_queue.isEmpty || !_queue.any((t) => t.id == track.id)) {
      _queue = [track];
      _currentIndex = 0;
    }

    if (_currentTrack?.id == track.id) {
      if (_isPlaying) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    _currentTrack = track;
    _currentStatus = null;
    notifyListeners();

    // Background fetch full track details to populate missing data (counts, artwork)
    _trackService
        ?.getTrackById(track.id)
        .then((fullTrack) {
          if (fullTrack != null && _currentTrack?.id == track.id) {
            // Update both the original object and the current track object
            track.artworkUrl = fullTrack.artworkUrl;
            track.likeCount = fullTrack.likeCount;
            track.commentCount = fullTrack.commentCount;
            track.repostCount = fullTrack.repostCount;
            track.isLiked = fullTrack.isLiked;
            track.isReposted = fullTrack.isReposted;

            _currentTrack = fullTrack;
            notifyListeners();
          }
        })
        .catchError(
          (e) => debugPrint('Error fetching track details in player: $e'),
        );

    onTrackStarted?.call(track);
    // Record eagerly so it shows up in history immediately
    _trackService?.recordPlay(track.id, durationPlayedMs: 0);

    // Use the cache-based load method
    loadWaveform(track.id);

    _trackService?.getTrackStatus(track.id).then((status) {
      if (_currentTrack?.id == track.id) {
        _currentStatus = status;
        notifyListeners();
      }
    });

    try {
      // Fetch the real stream URL from the API, fall back to track's audio_url
      String playUrl = track.streamUrl;

      if (_trackService != null) {
        final streamUrl = await _trackService.getStreamUrl(track.id);
        if (streamUrl != null && streamUrl.isNotEmpty) {
          playUrl = streamUrl;
        }
      }

      debugPrint('Playing track: ${track.title} (URL: $playUrl)');

      await _player.stop();

      await _player
          .setUrl(playUrl)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Track load timed out'),
          );

      await _player.play();
    } catch (e) {
      debugPrint('Error playing track: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> nextTrack() async {
    if (_queue.isEmpty || _currentIndex == -1) return;

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await playTrack(_queue[_currentIndex]);
    }
  }

  Future<void> previousTrack() async {
    if (_queue.isEmpty || _currentIndex == -1) return;

    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      await playTrack(_queue[_currentIndex]);
    }
  }

  Future<void> resume() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
