import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/track.dart';
import '../models/history_entry.dart';
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
    try {
      final url = genre != null
          ? '${ApiEndpoints.trendingTracks}?genre=$genre'
          : ApiEndpoints.trendingTracks;
      
      final response = await _apiService.get(url);
      
      if (response != null) {
        List<dynamic> items = [];
        if (response is List) {
          items = response;
        } else if (response is Map) {
          items = (response['data'] ?? response['tracks'] ?? response['items'] ?? []) as List;
        }

        return items.map((data) => Track.fromJson(data)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching real trending tracks: $e');
    }
    return []; // Return empty if anything fails
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    try {
      final response = await _apiService.get('${ApiEndpoints.tracks}?q=$query');
      
      if (response != null) {
        List<dynamic> items = [];
        if (response is List) {
          items = response;
        } else if (response is Map) {
          items = (response['data'] ?? response['tracks'] ?? response['items'] ?? []) as List;
        }

        return items.map((data) => Track.fromJson(data)).toList();
      }
    } catch (e) {
      debugPrint('Error searching tracks: $e');
    }
    return [];
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
  Future<void> recordPlay(String trackId, {int durationPlayedMs = 0}) async {
    debugPrint('DEBUG: Attempting to record play for track: $trackId');
    try {
      final response = await _apiService.post(
        ApiEndpoints.trackRecordPlay(trackId),
        body: {'duration_played_ms': durationPlayedMs},
        authRequired: true,
      );
      debugPrint('DEBUG: Record Play API Response: $response');
    } catch (e) {
      debugPrint('DEBUG: Error recording play for track $trackId: $e');
    }
  }

  @override
  Future<List<HistoryEntry>> getListeningHistory({
    int page = 1,
    int limit = 20,
  }) async {
    debugPrint('Fetching listening history (page: $page, limit: $limit)');
    final List<HistoryEntry> entries = [];
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.listeningHistory}?page=$page&limit=$limit',
        authRequired: true,
      );

      if (response != null) {
        debugPrint('DEBUG: Full History API Response: $response');
        List<dynamic> items = [];
        if (response is List) {
          items = response;
        } else if (response is Map) {
          items = (response['history'] ?? response['data'] ?? response['items'] ?? []) as List;
        }

        debugPrint('Found ${items.length} history items.');

        for (final item in items) {
          try {
            if (item is Map<String, dynamic>) {
              // The API returns track nested in 'track_id' field, but let's check 'track' too just in case
              Map<String, dynamic>? trackData;
              if (item['track_id'] is Map<String, dynamic>) {
                trackData = item['track_id'];
              } else if (item['track'] is Map<String, dynamic>) {
                trackData = item['track'];
              } else if (item.containsKey('title') || item.containsKey('stream_url')) {
                // Flat structure fallback
                trackData = item;
              }

              if (trackData == null) {
                debugPrint('Could not find valid track data in history item: $item');
                continue;
              }

              final track = Track.fromJson(trackData);
              final playedAt = item['played_at'] != null
                  ? DateTime.tryParse(item['played_at'].toString())
                  : null;
              final durationPlayedMs =
                  (item['duration_played_ms'] as num?)?.toInt() ?? 0;
              final isCompleted =
                  (item['is_completed'] as bool?) ?? false;

              entries.add(HistoryEntry(
                track: track,
                playedAt: playedAt ?? DateTime.now(),
                durationPlayedMs: durationPlayedMs,
                isCompleted: isCompleted,
              ));
            }
          } catch (e) {
            debugPrint('Error parsing history item: $e');
          }
        }
      } else {
        debugPrint('History API response was null');
      }
    } catch (e) {
      debugPrint('Error fetching listening history: $e');
    }

    debugPrint('Returning ${entries.length} history entries.');
    return entries;
  }

  @override
  Future<void> clearListeningHistory() async {
    try {
      await _apiService.delete(
        ApiEndpoints.clearListeningHistory,
        authRequired: true,
      );
      debugPrint('Listening history cleared.');
    } catch (e) {
      debugPrint('Error clearing history: $e');
      rethrow;
    }
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
