import 'package:flutter/material.dart';
// FIX: These imports now point to your actual folders based on your screenshot
import '../features/playlists/services/playlist_service.dart';
import '../features/playlists/models/playlist_model.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _service;
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _errorMessage;

  PlaylistProvider(this._service);

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. FETCH
  Future<void> fetchPlaylists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _playlists = await _service.getPlaylists();
    } catch (e) {
      _errorMessage = "Failed to load playlists.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. CREATE
  Future<bool> createPlaylist(String title) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newPlaylist = await _service.createPlaylist(title);
      if (newPlaylist != null) {
        _playlists.insert(0, newPlaylist);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. UPDATE (Fixed Null-Safety for 'id')
  Future<bool> updatePlaylist(String id, String title, String description) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        title: title,
        description: description,
      );
      notifyListeners(); 
    }

    try {
      final success = await _service.updatePlaylist(id, title, description);
      if (success) {
        await fetchPlaylists(); 
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 4. PRIVACY (Fixed 'updatePrivacy' error)
  Future<bool> updatePlaylistPrivacy(String id, bool makePublic) async {
    try {
      final success = makePublic 
          ? await _service.makePublic(id) 
          : await _service.makePrivate(id);

      if (success) {
        final index = _playlists.indexWhere((p) => p.id == id);
        if (index != -1) {
          _playlists[index] = _playlists[index].copyWith(isPublic: makePublic);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 5. ADD TRACK (Added Debugging Logs)
  Future<bool> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      debugPrint("Provider: Attempting to add track $trackId to playlist $playlistId");
      final success = await _service.addTrackToPlaylist(playlistId, trackId);
      
      if (success) {
        debugPrint("Provider: Add track SUCCESS. Refreshing playlists...");
        await fetchPlaylists();
        return true;
      } else {
        debugPrint("Provider: Add track FAILED (Service returned false).");
        return false;
      }
    } catch (e) {
      debugPrint("Provider ERROR in addTrackToPlaylist: $e");
      return false;
    }
  }

  // 6. REMOVE TRACK
  Future<bool> removeTrack(String playlistId, String trackId) async {
    try {
      final success = await _service.removeTrackFromPlaylist(playlistId, trackId);
      if (success) {
        await fetchPlaylists();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 7. DELETE (Fixed property 'id' error)
  Future<bool> deletePlaylist(String id) async {
    try {
      final success = await _service.deletePlaylist(id);
      if (success) {
        _playlists.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 8. REORDER
  Future<bool> reorderPlaylistTracks(String playlistId, List<String> trackIds) async {
    try {
      final success = await _service.reorderTracks(playlistId, trackIds);
      if (success) {
        await fetchPlaylists();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}