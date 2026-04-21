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
  List<double>? _currentWaveform;
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
  }

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  List<Track> get queue => _queue;
  int get currentIndex => _currentIndex;
  List<double>? get currentWaveform => _currentWaveform;
  Map<String, dynamic>? get currentStatus => _currentStatus;

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
    _currentWaveform = null;
    _currentStatus = null;
    notifyListeners();

    onTrackStarted?.call(track);
    // Record eagerly so it shows up in history immediately
    _trackService?.recordPlay(track.id, durationPlayedMs: 0);
    
    _trackService?.getTrackWaveform(track.id).then((wf) {
      if (_currentTrack?.id == track.id) {
        _currentWaveform = wf;
        notifyListeners();
      }
    });

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
      
      await _player.setUrl(playUrl).timeout(
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
