import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/track.dart';
import '../models/comment.dart';
import '../models/user.dart';
import 'track_service.dart';
import 'package:flutter/foundation.dart';

class ApiTrackService implements TrackService {
  final ApiService _apiService;

  // Local mock state for session persistence
  final List<Track> _localLikedTracks = [];
  final Map<String, List<Comment>> _localComments = {};

  // Cache for mock objects generated in recent calls
  final Map<String, Track> _mockTrackCache = {};

  ApiTrackService(this._apiService);

  @override
  Future<Track?> getTrackById(String id) async {
    try {
      final response = await _apiService.get(ApiEndpoints.trackById(id));
      if (response != null) {
        return Track.fromJson(response);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<List<double>?> getTrackWaveform(String trackId) async {
    try {
      final response = await _apiService
          .get(ApiEndpoints.trackWaveform(trackId), authRequired: true)
          .timeout(const Duration(seconds: 5));
      if (response != null && response is Map && response['peaks'] is List) {
        return (response['peaks'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      } else if (response != null && response is List) {
        return response.map((e) => (e as num).toDouble()).toList();
      } else if (response != null && response['data'] is List) {
        return (response['data'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }
    } catch (e) {
      // Return empty waveform on error or timeout
      return List.filled(50, 0.1);
    }
    return null;
  }

  @override
  Future<List<Track>> getArtistTracks(
    String artistId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.artistTracks(artistId, page: page, limit: limit),
      );
      if (response != null && response is List) {
        return response.map((data) => Track.fromJson(data)).toList();
      } else if (response != null && response['data'] is List) {
        return (response['data'] as List)
            .map((data) => Track.fromJson(data))
            .toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  @override
  Future<String?> getStreamUrl(String trackId) async {
    try {
      final response = await _apiService
          .get(ApiEndpoints.trackStreamUrl(trackId), authRequired: true)
          .timeout(const Duration(seconds: 10));
      if (response != null && response is Map && response['url'] != null) {
        return response['url'].toString();
      }
    } catch (e) {
      // Fall back to track's audio_url
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> getTrackStatus(String trackId) async {
    try {
      final response = await _apiService
          .get(ApiEndpoints.trackStatus(trackId), authRequired: true)
          .timeout(const Duration(seconds: 5));
      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      // Return default status on error
    }
    return {'track_id': trackId, 'status': 'Unknown', 'progress_percent': 0};
  }

  @override
  Future<List<Track>> getTrendingTracks({String? genre}) async {
    // Trending tracks are mocked as requested
    await Future.delayed(const Duration(milliseconds: 400));
    final tracks = [
      Track(
        id: 'trend_1',
        title: 'High Spirits',
        artistName: 'Midnight City',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
        artworkUrl: 'https://picsum.photos/400/400?random=1',
        createdAt: DateTime.now(),
        playCount: 12500,
      ),
      Track(
        id: 'trend_2',
        title: 'Neon Nights',
        artistName: 'Synthwave Prophet',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: const Duration(minutes: 4, seconds: 12),
        artworkUrl: 'https://picsum.photos/400/400?random=2',
        createdAt: DateTime.now(),
        playCount: 8900,
      ),
      Track(
        id: 'trend_3',
        title: 'Ocean Breeze',
        artistName: 'Summer Vibes',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        duration: const Duration(minutes: 2, seconds: 58),
        artworkUrl: 'https://picsum.photos/400/400?random=3',
        createdAt: DateTime.now(),
        playCount: 15400,
      ),
      Track(
        id: 'trend_4',
        title: 'Midnight Sun',
        artistName: 'Solar Echo',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        duration: const Duration(minutes: 3, seconds: 15),
        artworkUrl: 'https://picsum.photos/400/400?random=4',
        createdAt: DateTime.now(),
        playCount: 22100,
      ),
      Track(
        id: 'trend_5',
        title: 'Urban Jungle',
        artistName: 'Beat Maker X',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        duration: const Duration(minutes: 4, seconds: 45),
        artworkUrl: 'https://picsum.photos/400/400?random=5',
        createdAt: DateTime.now(),
        playCount: 5600,
      ),
      Track(
        id: 'trend_6',
        title: 'Electric Dreams',
        artistName: 'Cyber Vision',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        duration: const Duration(minutes: 3, seconds: 30),
        artworkUrl: 'https://picsum.photos/400/400?random=6',
        createdAt: DateTime.now(),
        playCount: 31200,
      ),
    ];
    for (var track in tracks) {
      _mockTrackCache[track.id] = track;
    }
    return tracks;
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    // Search tracks remain a robust mock as requested
    await Future.delayed(const Duration(milliseconds: 500));
    final tracks = [
      Track(
        id: 'search_1',
        title: '$query - Remix',
        artistName: 'Pro Producer',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
        duration: const Duration(minutes: 3, seconds: 20),
        artworkUrl: 'https://picsum.photos/400/400?random=11',
        createdAt: DateTime.now(),
      ),
      Track(
        id: 'search_2',
        title: 'The Best of $query',
        artistName: 'Compilation Experts',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
        duration: const Duration(minutes: 4, seconds: 05),
        artworkUrl: 'https://picsum.photos/400/400?random=12',
        createdAt: DateTime.now(),
      ),
      Track(
        id: 'search_3',
        title: '$query (Acoustic)',
        artistName: 'Soft Strings',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
        duration: const Duration(minutes: 2, seconds: 50),
        artworkUrl: 'https://picsum.photos/400/400?random=13',
        createdAt: DateTime.now(),
      ),
      Track(
        id: 'search_4',
        title: 'Forever $query',
        artistName: 'Legendary Band',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
        duration: const Duration(minutes: 5, seconds: 12),
        artworkUrl: 'https://picsum.photos/400/400?random=14',
        createdAt: DateTime.now(),
      ),
      Track(
        id: 'search_5',
        title: '$query - Night Drive',
        artistName: 'Afterhours',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
        duration: const Duration(minutes: 3, seconds: 55),
        artworkUrl: 'https://picsum.photos/400/400?random=15',
        createdAt: DateTime.now(),
      ),
    ];
    for (var track in tracks) {
      _mockTrackCache[track.id] = track;
    }
    return tracks;
  }

  @override
  Future<void> likeTrack(String trackId) async {
    // Check if it's a mock track
    if (trackId.startsWith('search_') || trackId.startsWith('trend_')) {
      final track = _mockTrackCache[trackId];
      if (track != null && !_localLikedTracks.any((t) => t.id == trackId)) {
        _localLikedTracks.add(track);
      }
      return;
    }

    try {
      await _apiService.post('/tracks/$trackId/like', body: {});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unlikeTrack(String trackId) async {
    if (trackId.startsWith('search_') || trackId.startsWith('trend_')) {
      _localLikedTracks.removeWhere((t) => t.id == trackId);
      return;
    }

    try {
      await _apiService.delete('/tracks/$trackId/like');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Track>> getLikedTracks() async {
    List<Track> realLikedTracks = [];
    try {
      final response = await _apiService.get(ApiEndpoints.likedTracks);
      if (response != null) {
        if (response is List) {
          realLikedTracks = response
              .map((data) => Track.fromJson(data))
              .toList();
        } else if (response['data'] is List) {
          realLikedTracks = (response['data'] as List)
              .map((data) => Track.fromJson(data))
              .toList();
        }
      }
    } catch (e) {
      rethrow;
    }

    // Merge real and local mock likes
    final merged = [..._localLikedTracks, ...realLikedTracks];
    final seen = <String>{};
    return merged.where((t) => seen.add(t.id)).toList();
  }

  @override
  Future<List<Track>> getActivityFeed() async {
    // Activity feed is mocked as requested
    await Future.delayed(const Duration(milliseconds: 400));
    final tracks = [
      Track(
        id: 'activity_1',
        title: 'Deep House Vibes',
        artistName: 'Luna Bay',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        duration: const Duration(minutes: 5, seconds: 12),
        artworkUrl: 'https://picsum.photos/200/200?random=10',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Track(
        id: 'activity_2',
        title: 'Midnight Wanderer',
        artistName: 'Echo Pulse',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
        artworkUrl: 'https://picsum.photos/200/200?random=11',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Track(
        id: 'activity_3',
        title: 'Golden Hour',
        artistName: 'Sunkissed',
        streamUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
        duration: const Duration(minutes: 4, seconds: 20),
        artworkUrl: 'https://picsum.photos/200/200?random=12',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];

    for (var track in tracks) {
      _mockTrackCache[track.id] = track;
    }
    return tracks;
  }

  @override
  Future<void> recordPlay(String trackId) async {
    debugPrint('Recording play for track: $trackId');

    try {
      final response = await _apiService.post(
        ApiEndpoints.trackStatus(trackId),
        body: {'status': 'played'},
        authRequired: true,
      );
      debugPrint('Record Play response: $response');
    } catch (e) {
      debugPrint('Error recording play: $e');
      rethrow;
    }
  }

  @override
  Future<List<Track>> getListeningHistory({
    int page = 1,
    int limit = 20,
  }) async {
    debugPrint(
      'Fetching listening history from API... (page: $page, limit: $limit)',
    );
    List<Track> realHistory = [];
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.listeningHistory}?page=$page&limit=$limit',
        authRequired: true,
      );

      if (response != null) {
        debugPrint('History API Response: $response');
        List<dynamic> items = [];
        if (response is List) {
          items = response;
        } else if (response is Map) {
          if (response['history'] is List) {
            items = response['history'] as List;
          } else if (response['data'] is List) {
            items = response['data'] as List;
          } else if (response['items'] is List) {
            items = response['items'] as List;
          } else {
            debugPrint(
              'History response Map detected but no "history", "data" or "items" list found.',
            );
          }
        }

        debugPrint('Found ${items.length} items in history response.');

        for (final item in items) {
          try {
            if (item is Map<String, dynamic>) {
              if (item.containsKey('track') &&
                  item['track'] is Map<String, dynamic>) {
                realHistory.add(Track.fromJson(item['track']));
              } else {
                realHistory.add(Track.fromJson(item));
              }
            }
          } catch (e) {
            debugPrint('Error parsing history item: $e');
          }
        }
      } else {
        debugPrint('History API Response was null');
      }
    } catch (e) {
      debugPrint('Error fetching listening history: $e');
    }

    debugPrint(
      'Returning ${realHistory.length} real history tracks from backend.',
    );

    final seen = <String>{};
    return realHistory.where((t) => seen.add(t.id)).toList();
  }

  @override
  Future<List<Comment>> getComments(String trackId) async {
    // Check mock
    if (trackId.startsWith('search_') || trackId.startsWith('trend_')) {
      return _localComments[trackId] ?? [];
    }

    try {
      final response = await _apiService.get('/tracks/$trackId/comments');
      if (response != null && response is List) {
        return response.map((data) => Comment.fromJson(data)).toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  @override
  Future<void> addComment(
    String trackId,
    String userId,
    String text,
    Duration timestampInTrack, {
    String? parentCommentId,
  }) async {
    final newComment = Comment(
      id: 'mock_comment_${DateTime.now().millisecondsSinceEpoch}',
      trackId: trackId,
      userId: userId,
      username: 'You (Mock)',
      text: text,
      timestampInTrack: timestampInTrack,
      createdAt: DateTime.now(),
    );

    // Check mock
    if (trackId.startsWith('search_') || trackId.startsWith('trend_')) {
      if (!_localComments.containsKey(trackId)) {
        _localComments[trackId] = [];
      }
      _localComments[trackId]!.insert(0, newComment);
      return;
    }

    try {
      await _apiService.post(
        '/tracks/$trackId/comments',
        body: {
          'text': text,
          'timestampSeconds': timestampInTrack.inSeconds,
          'parentCommentId': ?parentCommentId,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> likeComment(String commentId) async {}

  @override
  Future<void> unlikeComment(String commentId) async {}

  @override
  Future<List<User>> getTrackLikes(String trackId) async => [];

  @override
  Future<List<Track>> getUserTracks(String userId) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.tracks}?user_id=$userId',
      );
      if (response == null) return [];

      if (response is List) {
        return response.map((data) => Track.fromJson(data)).toList();
      } else if (response['data'] is List) {
        return (response['data'] as List)
            .map((data) => Track.fromJson(data))
            .toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  @override
  void setCurrentUser(User? user) {}
}
