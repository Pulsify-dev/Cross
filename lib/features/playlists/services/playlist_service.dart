import '../../../core/services/api_service.dart';
import '../models/playlist_model.dart';

class PlaylistService {
  final ApiService _apiService; 
  PlaylistService(this._apiService); 

  // 1. FETCH ALL
  Future<List<Playlist>> getPlaylists() async {
    final response = await _apiService.get(
      '/playlists',
      authRequired: true,
    );

    if (response != null) {
      final List? list = response is List ? response : response['data'];
      if (list != null) {
        return list.map((e) => Playlist.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    }
    return [];
  }

  // 2. CREATE
  Future<Playlist?> createPlaylist(String title) async {
    final response = await _apiService.post(
      '/playlists',
      body: {'title': title}, 
      authRequired: true,
    );

    if (response != null) {
      final data = response['data'] ?? response;
      return Playlist.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // 3. UPDATE (Fixed Path & Key for Smooth Sync)
  Future<bool> updatePlaylist(String id, String title, String description) async {
    final Map<String, dynamic> data = { 
      'title': title, // Matches your model and UI
      'description': description,
    };
    
    // Using the clean path from your Postman screenshot
    final response = await _apiService.patch(
      '/playlists/$id', 
      body: data, 
      authRequired: true,
    );
    
    return response != null;
  }

  // 4. PRIVACY (Direct calls based on Postman)
  Future<bool> makePrivate(String id) async {
    final response = await _apiService.patch(
      '/playlists/$id/private', 
      authRequired: true,
    );
    return response != null;
  }

  Future<bool> makePublic(String id) async {
    final response = await _apiService.patch(
      '/playlists/$id/public', 
      authRequired: true,
    );
    return response != null;
  }

  // 5. ADD TRACK (Fixed 404 - Removed /users/me/ to match Postman)
  Future<bool> addTrackToPlaylist(String playlistId, String trackId) async {
    final response = await _apiService.post(
      '/playlists/$playlistId/tracks', 
      body: {
        'trackId': trackId,
      }, 
      authRequired: true,
    );
    
    return response != null;
  }

  // 6. DELETE PLAYLIST
  Future<bool> deletePlaylist(String id) async {
    final response = await _apiService.delete(
      '/playlists/$id',
      authRequired: true,
    );
    return response != null;
  }

  // 7. REMOVE TRACK (New feature from your Postman)
  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final response = await _apiService.delete(
      '/playlists/$playlistId/tracks/$trackId', 
      authRequired: true,
    );
    return response != null;
  }

  // 8. REORDER TRACKS (New feature from your Postman)
  Future<bool> reorderTracks(String playlistId, List<String> trackIds) async {
    final response = await _apiService.post(
      '/playlists/$playlistId/reorder',
      body: {'trackIds': trackIds},
      authRequired: true,
    );
    return response != null;
  }

  // 9. SECRET TOKEN (New feature from your Postman)
  Future<String?> regenerateSecretToken(String id) async {
    final response = await _apiService.post(
      '/playlists/$id/token', 
      authRequired: true,
    );
    return response != null ? response['token'] : null;
  }
}