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
    notifyListeners();

    // Record play in history
    _trackService?.recordPlay(track.id);

    try {
      await _player.setUrl(track.streamUrl);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing track: $e');
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
