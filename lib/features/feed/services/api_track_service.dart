import '../models/feed_item.dart';
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
  Future<List<Track>> getTrendingTracks({
    String? genre,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String>[];
      if (genre != null) queryParams.add('genre=$genre');
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      
      final url = '${ApiEndpoints.trendingTracks}?${queryParams.join('&')}';
      
      final response = await _apiService.get(url);
      
      if (response != null) {
        List<dynamic> items = [];
        if (response is List) {
          items = response;
        } else if (response is Map) {
          final data = response['data'];
          if (data is List) {
            items = data;
          } else if (data is Map) {
            items = (data['tracks'] ?? data['items'] ?? []) as List;
          } else {
            items = (response['tracks'] ?? response['items'] ?? []) as List;
          }
        }

        return items.map((data) => Track.fromJson(data)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching real trending tracks: $e');
    }
    return []; // Return empty if anything fails
  }


  @override
  Future<void> likeTrack(String trackId) async {
    try {
      await _apiService.post(
        ApiEndpoints.trackLike(trackId),
        body: {},
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unlikeTrack(String trackId) async {
    try {
      await _apiService.delete(
        ApiEndpoints.trackLike(trackId),
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Track>> getLikedTracks() async {
    try {
      final response = await _apiService.get(ApiEndpoints.likedTracks, authRequired: true);
      if (response != null) {
        if (response is List) {
          return response.map((data) => Track.fromJson(data)).toList();
        } else if (response['data'] is List) {
          return (response['data'] as List)
              .map((data) => Track.fromJson(data))
              .toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  @override
  Future<bool> isTrackLiked(String trackId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.trackIsLiked(trackId),
        authRequired: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['liked'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking if track is liked: $e');
    }
    return false;
  }

  @override
  Future<List<FeedItem>> getFeed({
    int page = 1,
    int limit = 20,
    bool authRequired = true,
  }) async {
    try {
      final response = await _apiService.get(
        '${ApiEndpoints.feed}?page=$page&limit=$limit',
        authRequired: authRequired,
      );

      if (response != null && response is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null && data['items'] != null) {
          final items = data['items'] as List;
          return items
              .map((i) => FeedItem.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching feed: $e');
    }
    return [];
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
  Future<({List<Comment> comments, int total})> getComments(String trackId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.trackComments(trackId));
      if (response != null && response is Map<String, dynamic>) {
        final commentsData = response['comments'] as List?;
        final total = response['comments_count'] ?? 0;
        if (commentsData != null) {
          final comments = commentsData
              .map((data) => Comment.fromJson(data as Map<String, dynamic>))
              .toList();
          return (comments: comments, total: total as int);
        }
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    }
    return (comments: <Comment>[], total: 0);
  }

  @override
  Future<({List<Comment> replies, int total})> getCommentReplies(String commentId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.commentReplies(commentId));
      if (response != null && response is Map<String, dynamic>) {
        final repliesData = response['replies'] as List?;
        final total = response['replies_count'] ?? 0;
        if (repliesData != null) {
          final replies = repliesData
              .map((data) => Comment.fromJson(data as Map<String, dynamic>))
              .toList();
          return (replies: replies, total: total as int);
        }
      }
    } catch (e) {
      debugPrint('Error fetching replies: $e');
    }
    return (replies: <Comment>[], total: 0);
  }

  @override
  Future<void> addComment(
    String trackId,
    String userId,
    String text,
    Duration timestampInTrack, {
    String? parentCommentId,
  }) async {
    try {
      await _apiService.post(
        ApiEndpoints.trackComments(trackId),
        body: {
          'text': text,
          'timestamp_seconds': timestampInTrack.inSeconds,
          'parent_comment_id': parentCommentId,
        },
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> likeComment(String commentId) async {}

  @override
  Future<void> updateComment(String commentId, String text) async {
    try {
      await _apiService.patch(
        ApiEndpoints.commentAction(commentId),
        body: {'text': text},
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await _apiService.delete(
        ApiEndpoints.commentAction(commentId),
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unlikeComment(String commentId) async {}

  @override
  Future<List<User>> getTrackLikes(String trackId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.trackLikes(trackId));
      if (response != null && response is Map<String, dynamic>) {
        final likers = response['likers'] as List?;
        if (likers != null) {
          return likers
              .map((u) => User.fromJson(u as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching track likes: $e');
    }
    return [];
  }

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
  Future<void> repostTrack(String trackId) async {
    try {
      await _apiService.post(
        ApiEndpoints.trackRepost(trackId),
        body: {},
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unrepostTrack(String trackId) async {
    try {
      await _apiService.delete(
        ApiEndpoints.trackRepost(trackId),
        authRequired: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isTrackReposted(String trackId) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.trackIsReposted(trackId),
        authRequired: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['reposted'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking if track is reposted: $e');
    }
    return false;
  }

  @override
  Future<List<User>> getTrackReposts(String trackId) async {
    try {
      final response = await _apiService.get(ApiEndpoints.trackReposts(trackId));
      if (response != null && response is Map<String, dynamic>) {
        final reposters = response['reposters'] as List?;
        if (reposters != null) {
          return reposters
              .map((u) => User.fromJson(u as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching track reposts: $e');
    }
    return [];
  }

  void setCurrentUser(User? user) {}
}
