import 'package:flutter/foundation.dart';
import '../features/feed/models/track.dart';
import '../features/feed/models/user.dart';
import '../features/feed/services/track_service.dart';

class FeedProvider with ChangeNotifier {
  final TrackService _trackService;
  List<Track> _trendingTracks = [];
  List<Track> _activityFeed = [];
  List<Track> _listeningHistory = [];
  List<Track> _likedTracks = [];
  List<Track> _userTracks = [];
  bool _isLoading = false;
  bool _isTrendingLoading = false;
  String? _error;
  String? _selectedGenre;
  List<User> _suggestedArtists = [];

  FeedProvider(this._trackService);

  List<Track> get trendingTracks => _trendingTracks;
  List<Track> get activityFeed => _activityFeed;
  List<Track> get listeningHistory => _listeningHistory;
  List<Track> get likedTracks => _likedTracks;
  List<Track> get userTracks => _userTracks;
  bool get isLoading => _isLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  String? get error => _error;
  String? get selectedGenre => _selectedGenre;
  List<User> get suggestedArtists => _suggestedArtists;

  Future<void> fetchTrendingTracks() async {
    _isTrendingLoading = true;
    notifyListeners();
    _error = null;
    try {
      _trendingTracks = await _trackService.getTrendingTracks(
        genre: _selectedGenre,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isTrendingLoading = false;
      notifyListeners();
    }
  }

  void setGenre(String? genre) {
    if (_selectedGenre == genre) return;
    _selectedGenre = genre;
    notifyListeners();
    fetchTrendingTracks();
  }

  Future<void> fetchUserTracks(String userId) async {
    _isLoading = true;
    notifyListeners();
    _error = null;
    try {
      _userTracks = await _trackService.getUserTracks(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSuggestedArtists() async {
    _setLoading(true);
    _error = null;
    try {
      _suggestedArtists = await _trackService.getSuggestedArtists();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchActivityFeed() async {
    _setLoading(true);
    _error = null;
    try {
      _activityFeed = await _trackService.getActivityFeed();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchListeningHistory() async {
    _setLoading(true);
    _error = null;
    try {
      _listeningHistory = await _trackService.getListeningHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchLikedTracks() async {
    _setLoading(true);
    _error = null;
    try {
      _likedTracks = await _trackService.getLikedTracks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleLike(Track track) async {
    final trackId = track.id;
    if (track.isLiked) {
      track.isLiked = false;
      track.likeCount--;
      notifyListeners();
      await _trackService.unlikeTrack(trackId);
    } else {
      track.isLiked = true;
      track.likeCount++;
      if (!_likedTracks.any((t) => t.id == trackId)) {
        _likedTracks.add(track);
      }
      notifyListeners();
      await _trackService.likeTrack(trackId);
    }
  }

  void cleanupUnlikedTracks() {
    _likedTracks.removeWhere((t) => !t.isLiked);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
