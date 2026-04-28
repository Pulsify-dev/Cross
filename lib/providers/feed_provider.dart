import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/feed/models/feed_item.dart';
import '../features/feed/models/track.dart';
import '../features/feed/models/history_entry.dart';
import '../features/feed/models/discover_section.dart';
import '../features/feed/services/track_service.dart';
import '../features/feed/services/user_service.dart';
import '../features/feed/models/user.dart';
import '../features/social/services/social_service.dart';

class FeedProvider with ChangeNotifier {
  final TrackService _trackService;
  final UserService _userService;
  SocialService? _socialService;
  List<Track> _trendingTracks = [];
  List<FeedItem> _feed = [];
  List<Track> _discoveryFeed = [];
  List<DiscoverSection> _discoverHomeSections = [];
  List<HistoryEntry> _listeningHistory = [];
  List<Track> _recentlyPlayed = [];
  List<Track> _likedTracks = [];
  List<Track> _userTracks = [];
  bool _isLoading = false;
  bool _isDiscoveryLoading = false;
  bool _isDiscoverHomeLoading = false;
  bool _isTrendingLoading = false;
  String? _error;
  String? _selectedGenre;

  // History pagination
  int _historyPage = 1;
  static const int _historyLimit = 20;
  bool _hasMoreHistory = true;
  bool _isHistoryLoading = false;
  final Set<String> _followingUserIds = {};
  final Set<String> _blockedByMeUserIds = {};
  final Set<String> _blockedByThemUserIds = {};
  final Set<String> _mutualUserIds = {};
  final Set<String> _relationshipFetchedIds = {};

  FeedProvider(this._trackService, this._userService, {SocialService? socialService})
      : _socialService = socialService;

  void setSocialService(SocialService service) {
    _socialService = service;
  }

  List<Track> get trendingTracks => _trendingTracks;
  List<FeedItem> get feed => _feed;
  List<Track> get discoveryFeed => _discoveryFeed;
  List<DiscoverSection> get discoverHomeSections => _discoverHomeSections;
  List<HistoryEntry> get listeningHistory => _listeningHistory;
  List<Track> get recentlyPlayed => _recentlyPlayed;
  List<Track> get likedTracks => _likedTracks;
  List<Track> get userTracks => _userTracks;
  bool get isLoading => _isLoading;
  bool get isDiscoveryLoading => _isDiscoveryLoading;
  bool get isDiscoverHomeLoading => _isDiscoverHomeLoading;
  bool get isTrendingLoading => _isTrendingLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get hasMoreHistory => _hasMoreHistory;
  String? get error => _error;
  String? get selectedGenre => _selectedGenre;

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

  bool isUserBlocked(String userId) {
    return _blockedByMeUserIds.contains(userId) ||
        _blockedByThemUserIds.contains(userId);
  }

  bool isUserMutual(String userId) {
    return _mutualUserIds.contains(userId);
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

  Future<void> fetchFeed() async {
    _setLoading(true);
    _error = null;
    try {
      final fetchedFeed = await _trackService.getFeed(authRequired: true);
      _feed = fetchedFeed.where((item) => item.track != null).toList();
      _syncFeedItemStatuses(_feed);
      // Fetch relationship statuses for all uploaders
      final tracks = _feed.map((e) => e.track).whereType<Track>().toList();
      _fetchRelationshipStatuses(tracks);
      // Enrich uploader avatars in background
      _enrichUploaderProfiles(tracks);
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
      _discoveryFeed = await _trackService.getDiscoverFeed();
      _syncTrackStatuses(_discoveryFeed);
      // Fetch relationship statuses for all uploaders
      _fetchRelationshipStatuses(_discoveryFeed);
      // Enrich uploader avatars in background
      _enrichUploaderProfiles(_discoveryFeed);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDiscoveryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDiscoverHome() async {
    _isDiscoverHomeLoading = true;
    notifyListeners();
    _error = null;
    try {
      _discoverHomeSections = await _trackService.getDiscoverHome();
      // Sync track statuses for all tracks across all sections
      for (final section in _discoverHomeSections) {
        _syncTrackStatuses(section.items);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDiscoverHomeLoading = false;
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
    final nowFollowing = !wasFollowing;
    
    // Optimistic update
    if (nowFollowing) {
      _followingUserIds.add(userId);
    } else {
      _followingUserIds.remove(userId);
      _mutualUserIds.remove(userId);
    }
    notifyListeners();

    try {
      if (_socialService != null) {
        // Use SocialService for full relationship response
        final status = wasFollowing
            ? await _socialService!.unfollowUser(userId)
            : await _socialService!.followUser(userId);

        // Trust the intended action for follow state — the API call
        // succeeded, so the action was applied. The response might
        // contain stale isFollowing data due to caching/race conditions.
        if (nowFollowing) {
          _followingUserIds.add(userId);
        } else {
          _followingUserIds.remove(userId);
        }

        // Use response for mutual/blocked state (these are server-authoritative)
        if (nowFollowing && status.isFollowedBy) {
          _mutualUserIds.add(userId);
        } else {
          _mutualUserIds.remove(userId);
        }
        if (status.isBlockedByMe) {
          _blockedByMeUserIds.add(userId);
        } else {
          _blockedByMeUserIds.remove(userId);
        }
        if (status.isBlockedByThem) {
          _blockedByThemUserIds.add(userId);
        } else {
          _blockedByThemUserIds.remove(userId);
        }
        _relationshipFetchedIds.add(userId);
      } else {
        // Fallback to UserService
        if (wasFollowing) {
          await _userService.unfollowUser(userId);
        } else {
          await _userService.followUser(userId);
        }
      }
      notifyListeners();
    } catch (e) {
      // Rollback on error
      if (wasFollowing) {
        _followingUserIds.add(userId);
      } else {
        _followingUserIds.remove(userId);
        _mutualUserIds.remove(userId);
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

  /// Fetches public profiles for tracks missing uploader data or avatar.
  /// Creates/updates the track's uploader User with profileImageUrl.
  Future<void> _enrichUploaderProfiles(List<Track> tracks) async {
    final enriched = <String>{};

    for (final track in tracks) {
      final uid = track.uploader?.id ?? track.artistId;
      if (uid == null || uid.isEmpty || enriched.contains(uid)) continue;

      // Skip if uploader already has a valid avatar
      if (track.uploader?.profileImageUrl != null &&
          track.uploader!.profileImageUrl!.isNotEmpty) {
        continue;
      }

      enriched.add(uid);

      try {
        final profile = await _userService.getPublicProfile(uid);
        if (profile == null) continue;

        // Update all tracks with the same uploader
        for (final t in tracks) {
          final tUid = t.uploader?.id ?? t.artistId;
          if (tUid != uid) continue;

          if (t.uploader != null) {
            // Update existing uploader with avatar from profile
            t.uploader = t.uploader!.copyWith(
              profileImageUrl: profile.profileImageUrl,
            );
          } else {
            // Create uploader from profile data
            t.uploader = User(
              id: profile.id,
              username: profile.username,
              displayName: profile.displayName,
              profileImageUrl: profile.profileImageUrl,
            );
          }

          if (t.artistName == 'Unknown Artist' || t.artistName.isEmpty) {
            t.artistName = profile.displayName;
          }
          if (t.artistId == null || t.artistId!.isEmpty) {
            t.artistId = profile.id;
          }
        }

        notifyListeners();
      } catch (e) {
        debugPrint('Error enriching uploader profile $uid: $e');
      }
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
      // Note: blocked/mutual data comes from relationship API;
      // the uploader object doesn't carry these fields.
    }
  }

  void _syncFeedItemStatuses(List<FeedItem> items) {
    _syncTrackStatuses(items.map((e) => e.track).whereType<Track>().toList());
  }

  /// Fetches relationship status for each unique uploader in the tracks
  /// using the SocialService.getRelationshipStatus API.
  /// Updates _followingUserIds, _blockedByMeUserIds, _blockedByThemUserIds,
  /// and _mutualUserIds based on the response.
  Future<void> _fetchRelationshipStatuses(List<Track> tracks) async {
    if (_socialService == null) return;

    // Collect unique uploader IDs that haven't been fetched yet
    final uploaderIds = <String>{};
    for (final track in tracks) {
      final uid = track.uploader?.id ?? track.artistId;
      if (uid != null && uid.isNotEmpty && !_relationshipFetchedIds.contains(uid)) {
        uploaderIds.add(uid);
      }
    }

    if (uploaderIds.isEmpty) return;

    // Fetch in parallel for performance
    for (final userId in uploaderIds) {
      try {
        final status = await _socialService!.getRelationshipStatus(userId);
        _relationshipFetchedIds.add(userId);

        // Update follow state
        if (status.isFollowing) {
          _followingUserIds.add(userId);
        } else {
          _followingUserIds.remove(userId);
        }

        // Update blocked state
        if (status.isBlockedByMe) {
          _blockedByMeUserIds.add(userId);
        } else {
          _blockedByMeUserIds.remove(userId);
        }
        if (status.isBlockedByThem) {
          _blockedByThemUserIds.add(userId);
        } else {
          _blockedByThemUserIds.remove(userId);
        }

        // Update mutual state
        if (status.isMutual) {
          _mutualUserIds.add(userId);
        } else {
          _mutualUserIds.remove(userId);
        }
      } catch (e) {
        debugPrint('Error fetching relationship for $userId: $e');
      }
    }

    notifyListeners();
  }
}
