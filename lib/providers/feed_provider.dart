import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/feed/models/feed_item.dart';
import '../features/feed/models/track.dart';
import '../features/feed/models/history_entry.dart';
import '../features/feed/models/user.dart';
import '../features/feed/services/track_service.dart';
import '../features/feed/services/user_service.dart';

class FeedProvider with ChangeNotifier {
  final TrackService _trackService;
  final UserService _userService;
  List<Track> _trendingTracks = [];
  List<FeedItem> _feed = [];
  List<FeedItem> _discoveryFeed = [];
  List<HistoryEntry> _listeningHistory = [];
  List<Track> _recentlyPlayed = [];
  List<Track> _likedTracks = [];
  List<Track> _userTracks = [];
  bool _isLoading = false;
  bool _isDiscoveryLoading = false;
  bool _isTrendingLoading = false;
  String? _error;
  String? _selectedGenre;
  List<User> _suggestedUsers = [];

  // History pagination
  int _historyPage = 1;
  static const int _historyLimit = 20;
  bool _hasMoreHistory = true;
  bool _isHistoryLoading = false;
  final Set<String> _followingUserIds = {};

  FeedProvider(this._trackService, this._userService);

  List<Track> get trendingTracks => _trendingTracks;
  List<FeedItem> get feed => _feed;
  List<FeedItem> get discoveryFeed => _discoveryFeed;
  List<HistoryEntry> get listeningHistory => _listeningHistory;
  List<Track> get recentlyPlayed => _recentlyPlayed;
  List<Track> get likedTracks => _likedTracks;
  List<Track> get userTracks => _userTracks;
  bool get isLoading => _isLoading;
  bool get isDiscoveryLoading => _isDiscoveryLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get hasMoreHistory => _hasMoreHistory;
  String? get error => _error;
  String? get selectedGenre => _selectedGenre;
  List<User> get suggestedUsers => _suggestedUsers;

  final Map<String, int> _trackLikeCounts = {};
  final Set<String> _repostedTrackIds = {};
  final Map<String, int> _trackRepostCounts = {};

  bool isTrackLiked(String trackId) {
    return _likedTracks.any((t) => t.id == trackId);
  }

  int getTrackLikeCount(Track track) {
    return _trackLikeCounts[track.id] ?? track.likeCount;
  }

  bool isFollowingUser(String userId) {
    return _followingUserIds.contains(userId);
  }

  bool isTrackReposted(String trackId) {
    return _repostedTrackIds.contains(trackId);
  }

  int getTrackRepostCount(Track track) {
    return _trackRepostCounts[track.id] ?? track.repostCount;
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

  Future<void> fetchFeed() async {
    _setLoading(true);
    _error = null;
    try {
      final fetchedFeed = await _trackService.getFeed(authRequired: true);
      _feed = fetchedFeed.where((item) => item.track != null).toList();
      _syncFeedItemStatuses(_feed);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDiscoveryFeed() async {
    _isDiscoveryLoading = true;
    notifyListeners();
    _error = null;
    try {
      final fetchedDiscoveryFeed = await _trackService.getFeed(authRequired: false);
      _discoveryFeed = fetchedDiscoveryFeed.where((item) => item.track != null).toList();
      _syncFeedItemStatuses(_discoveryFeed);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDiscoveryLoading = false;
      notifyListeners();
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
      _enrichHistoryArtists(entries);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecentlyPlayed() async {
    _isHistoryLoading = true;
    _error = null;
    notifyListeners();
    try {
      _recentlyPlayed = await _trackService.getRecentlyPlayed();
      _syncTrackStatuses(_recentlyPlayed);
      _enrichTracks(_recentlyPlayed);
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
      _enrichHistoryArtists(entries);
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
    final isLiked = isTrackLiked(trackId);

    try {
      if (isLiked) {
        await _trackService.unlikeTrack(trackId);
        _likedTracks.removeWhere((t) => t.id == trackId);
        _trackLikeCounts[trackId] = (getTrackLikeCount(track) > 0) ? getTrackLikeCount(track) - 1 : 0;
        track.isLiked = false;
        track.likeCount = _trackLikeCounts[trackId]!;
      } else {
        await _trackService.likeTrack(trackId);
        _likedTracks.add(track);
        _trackLikeCounts[trackId] = getTrackLikeCount(track) + 1;
        track.isLiked = true;
        track.likeCount = _trackLikeCounts[trackId]!;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkIfLiked(Track track) async {
    try {
      final isLiked = await _trackService.isTrackLiked(track.id);
      if (isLiked != track.isLiked) {
        track.isLiked = isLiked;
        if (isLiked) {
          if (!_likedTracks.any((t) => t.id == track.id)) {
            _likedTracks.add(track);
          }
        } else {
          _likedTracks.removeWhere((t) => t.id == track.id);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking like status: $e');
    }
  }

  Future<void> toggleRepost(Track track) async {
    final trackId = track.id;
    final isReposted = isTrackReposted(trackId);
    try {
      if (isReposted) {
        await _trackService.unrepostTrack(trackId);
        _repostedTrackIds.remove(trackId);
        _trackRepostCounts[trackId] =
            (getTrackRepostCount(track) > 0) ? getTrackRepostCount(track) - 1 : 0;
        track.isReposted = false;
        track.repostCount = _trackRepostCounts[trackId]!;
      } else {
        await _trackService.repostTrack(trackId);
        _repostedTrackIds.add(trackId);
        _trackRepostCounts[trackId] = getTrackRepostCount(track) + 1;
        track.isReposted = true;
        track.repostCount = _trackRepostCounts[trackId]!;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFollow(String userId) async {
    if (userId.isEmpty) return;
    
    final wasFollowing = isFollowingUser(userId);
    
    // Optimistic update
    if (wasFollowing) {
      _followingUserIds.remove(userId);
    } else {
      _followingUserIds.add(userId);
    }
    notifyListeners();

    try {
      if (wasFollowing) {
        await _userService.unfollowUser(userId);
      } else {
        await _userService.followUser(userId);
      }
    } catch (e) {
      // Rollback on error
      if (wasFollowing) {
        _followingUserIds.add(userId);
      } else {
        _followingUserIds.remove(userId);
      }
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkIfReposted(Track track) async {
    try {
      final isReposted = await _trackService.isTrackReposted(track.id);
      if (isReposted != track.isReposted) {
        track.isReposted = isReposted;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking repost status: $e');
    }
  }

  Future<void> _enrichTracks(List<Track> tracks) async {
    for (final track in tracks) {
      if ((track.artistName == 'Unknown Artist' ||
              track.artistName.isEmpty) &&
          track.artistId != null &&
          track.artistId!.isNotEmpty) {
        try {
          final profile =
              await _userService.getPublicProfile(track.artistId!);
          if (profile != null) {
            track.artistName = profile.displayName;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Error enriching artist ${track.artistId}: $e');
        }
      }
    }
  }

  Future<void> _enrichHistoryArtists(List<HistoryEntry> entries) async {
    await _enrichTracks(entries.map((e) => e.track).toList());
  }

  void cleanupUnlikedTracks() {
    _likedTracks.removeWhere((t) => !t.isLiked);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _syncTrackStatuses(List<Track> tracks) {
    for (final track in tracks) {
      if (track.isLiked && !isTrackLiked(track.id)) {
        if (!_likedTracks.any((t) => t.id == track.id)) {
          _likedTracks.add(track);
        }
      }
      if (track.isReposted) {
        _repostedTrackIds.add(track.id);
      }
      _trackLikeCounts[track.id] = track.likeCount;
      _trackRepostCounts[track.id] = track.repostCount;
      if (track.uploader != null && track.uploader!.isFollowing) {
        _followingUserIds.add(track.uploader!.id);
      }
    }
  }

  void _syncFeedItemStatuses(List<FeedItem> items) {
    _syncTrackStatuses(items.map((e) => e.track).whereType<Track>().toList());
  }
}
