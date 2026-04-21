import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/feed/models/track.dart';
import '../features/feed/models/history_entry.dart';
import '../features/feed/models/user.dart';
import '../features/feed/services/track_service.dart';
import '../features/feed/services/user_service.dart';

class FeedProvider with ChangeNotifier {
  final TrackService _trackService;
  final UserService _userService;
  List<Track> _trendingTracks = [];
  List<Track> _activityFeed = [];
  List<HistoryEntry> _listeningHistory = [];
  List<Track> _likedTracks = [];
  List<Track> _userTracks = [];
  bool _isLoading = false;
  bool _isTrendingLoading = false;
  String? _error;
  String? _selectedGenre;
  List<User> _suggestedArtists = [];
  List<User> _suggestedUsers = [];

  // History pagination
  int _historyPage = 1;
  static const int _historyLimit = 20;
  bool _hasMoreHistory = true;
  bool _isHistoryLoading = false;

  FeedProvider(this._trackService, this._userService);

  List<Track> get trendingTracks => _trendingTracks;
  List<Track> get activityFeed => _activityFeed;
  List<HistoryEntry> get listeningHistory => _listeningHistory;
  List<Track> get likedTracks => _likedTracks;
  List<Track> get userTracks => _userTracks;
  bool get isLoading => _isLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get hasMoreHistory => _hasMoreHistory;
  String? get error => _error;
  String? get selectedGenre => _selectedGenre;
  List<User> get suggestedArtists => _suggestedArtists;
  List<User> get suggestedUsers => _suggestedUsers;

  final Map<String, int> _trackLikeCounts = {};

  bool isTrackLiked(String trackId) {
    return _likedTracks.any((t) => t.id == trackId);
  }

  int getTrackLikeCount(Track track) {
    return _trackLikeCounts[track.id] ?? track.likeCount;
  }

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

  Future<void> fetchSuggestedUsers() async {
    _setLoading(true);
    _error = null;
    try {
      _suggestedUsers = await _userService.getSuggestedUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSuggestedArtists() async {
    _setLoading(true);
    _error = null;
    try {
      _suggestedArtists = await _userService.getSuggestedArtists();
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

  /// Resets and fetches the first page of listening history.
  Future<void> fetchListeningHistory() async {
    _historyPage = 1;
    _hasMoreHistory = true;
    _listeningHistory = [];
    _isHistoryLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entries = await _trackService.getListeningHistory(
        page: _historyPage,
        limit: _historyLimit,
      );
      _listeningHistory = entries;
      _hasMoreHistory = entries.length >= _historyLimit;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  /// Appends the next page of history entries.
  Future<void> fetchMoreHistory() async {
    if (_isHistoryLoading || !_hasMoreHistory) return;

    _historyPage++;
    _isHistoryLoading = true;
    notifyListeners();

    try {
      final entries = await _trackService.getListeningHistory(
        page: _historyPage,
        limit: _historyLimit,
      );
      _listeningHistory = [..._listeningHistory, ...entries];
      _hasMoreHistory = entries.length >= _historyLimit;
    } catch (e) {
      _historyPage--; // rollback on error
      _error = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  /// Clears the entire listening history via the API and locally.
  Future<void> clearListeningHistory() async {
    _isHistoryLoading = true;
    notifyListeners();
    try {
      await _trackService.clearListeningHistory();
      _listeningHistory = [];
      _historyPage = 1;
      _hasMoreHistory = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
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
      _likedTracks.removeWhere((t) => t.id == trackId);
      notifyListeners();

      try {
        await _trackService.unlikeTrack(trackId);
      } catch (e) {
        track.isLiked = true;
        track.likeCount++;
        _likedTracks.add(track);
        notifyListeners();
      }
    } else {
      track.isLiked = true;
      track.likeCount++;
      _likedTracks.add(track);
      notifyListeners();

      try {
        await _trackService.likeTrack(trackId);
      } catch (e) {
        track.isLiked = false;
        track.likeCount--;
        _likedTracks.removeWhere((t) => t.id == trackId);
        notifyListeners();
      }
    }
  }

  Future<void> toggleRepost(Track track) async {
    if (track.isReposted) {
      track.isReposted = false;
      track.repostCount--;
      notifyListeners();
    } else {
      track.isReposted = true;
      track.repostCount++;
      notifyListeners();
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
