import '../../../core/services/api_service.dart';
import '../models/playlist_model.dart';

class PlaylistService {
  final ApiService _apiService; 
  PlaylistService(this._apiService); 

  // 1. FETCH ALL
  Future<List<Playlist>> getPlaylists(String token) async {
    final response = await _apiService.get(
      '/playlists',
      authRequired: true,
    );

    if (response != null && response is List) {
      return response.map((e) => Playlist.fromJson(e)).toList();
    }
    return [];
  }

  // 2. CREATE
  Future<Playlist?> createPlaylist(String token, String title) async {
    final response = await _apiService.post(
      '/playlists',
      {'name': title}, 
      authRequired: true,
    );

    if (response != null) {
      return Playlist.fromJson(response);
    }
    return null;
  }

Future<bool> updatePlaylist(String token, String id, String name, String description) async {
  // Use 'data' to avoid clashing with the reserved word 'body'
  final Map<String, dynamic> data = { 
    'name': name,
    'description': description,
  };

  final response = await _apiService.put(
    '/playlists/$id',
  );
  return response != null;
}
  // 4. UPDATE PRIVACY (Toggle)
  Future<bool> updatePrivacy(String token, String id, bool isPublic) async {
    final response = await _apiService.patch(
      '/playlists/$id',
      {'isPublic': isPublic},
    );
    return response != null;
  }

  // 5. ADD TRACK
  Future<bool> addTrack(String token, String playlistId, String trackId) async {
    final response = await _apiService.post(
      '/playlists/$playlistId/tracks',
      {'trackId': trackId},
      authRequired: true,
    );
    return response != null;
  }

  // 6. DELETE
  Future<bool> deletePlaylist(String token, String id) async {
    final response = await _apiService.delete(
      '/playlists/$id',
      authRequired: true,
    );
    return response != null;
  }
}