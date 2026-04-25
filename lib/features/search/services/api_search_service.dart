import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/search_models.dart';
import 'search_service.dart';

import '../../feed/services/track_service.dart';
import '../../feed/services/user_service.dart';

class ApiSearchService implements SearchService {
  final ApiService _apiService;
  final TrackService _trackService;
  final UserService _userService;

  ApiSearchService(this._apiService, this._trackService, this._userService);

  @override
  Future<GlobalSearchResponse> search(String query, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.globalSearch(query, limit: limit, offset: offset),
      );
      if (response != null && response is Map<String, dynamic>) {
        final searchResult = GlobalSearchResponse.fromJson(response);
        
        // Enrich the tracks in parallel
        if (searchResult.tracks.isNotEmpty) {
          await Future.wait(searchResult.tracks.map((track) async {
            try {
              final fullTrack = await _trackService.getTrackById(track.id);
              if (fullTrack != null) {
                track.artworkUrl = fullTrack.artworkUrl;
                track.likeCount = fullTrack.likeCount;
                track.commentCount = fullTrack.commentCount;
                track.repostCount = fullTrack.repostCount;
                track.isLiked = fullTrack.isLiked;
                track.isReposted = fullTrack.isReposted;
              }
            } catch (e) {
              // Ignore individual fetch errors so we don't break the whole search
            }
          }));
        }

        // Enrich the users in parallel using getPublicProfile
        if (searchResult.users.isNotEmpty) {
          await Future.wait(searchResult.users.asMap().entries.map((entry) async {
            final index = entry.key;
            final user = entry.value;
            try {
              final fullProfile = await _userService.getPublicProfile(user.id);
              if (fullProfile != null && fullProfile.profileImageUrl != null) {
                searchResult.users[index] = user.copyWith(
                  profileImageUrl: fullProfile.profileImageUrl,
                  displayName: fullProfile.displayName,
                  bio: fullProfile.bio,
                  followersCount: fullProfile.followersCount,
                );
              }
            } catch (e) {
              // Ignore individual fetch errors
            }
          }));
        }
        
        return searchResult;
      }
    } catch (e) {
      rethrow;
    }
    return GlobalSearchResponse();
  }

  @override
  Future<List<SearchSuggestion>> getSuggestions(String query, {int limit = 10}) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.searchSuggestions(query, limit: limit),
      );
      if (response != null && response is Map<String, dynamic> && response['data'] != null) {
        final data = response['data'] as List;
        return data.map((i) => SearchSuggestion.fromJson(i as Map<String, dynamic>)).toList();
      } else if (response != null && response is List) {
        return response.map((i) => SearchSuggestion.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Don't rethrow for suggestions, just return empty list to avoid UI flicker/error
    }
    return [];
  }
}
