import 'package:cross/features/playlists/services/playlist_service.dart';
import 'package:flutter/material.dart';
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

  Future<void> fetchPlaylists(String token) async {
    if (token.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _playlists = await _service.getPlaylists(token);
    } catch (e) {
      _errorMessage = "Failed to load playlists.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPlaylist(String token, String name) async {
    if (token.isEmpty) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final newPlaylist = await _service.createPlaylist(token, name);
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

  Future<bool> deletePlaylist(String token, String id) async {
    try {
      final success = await _service.deletePlaylist(token, id);
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

 Future<bool> updatePlaylist(String token, String id, String title, String description) async {
  try {
    final success = await _service.updatePlaylist(token, id, title, description);
    if (success) {
      final index = _playlists.indexWhere((p) => p.id == id);
      if (index != -1) {
        _playlists[index] = _playlists[index].copyWith(
          title: title,
          description: description,
        );
        notifyListeners();
      }
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
 }

  Future<bool> updatePlaylistPrivacy(String token, String id, bool isPublic) async {
    try {
      final success = await _service.updatePrivacy(token, id, isPublic);
      if (success) {
        final index = _playlists.indexWhere((p) => p.id == id);
        if (index != -1) {
          _playlists[index] = _playlists[index].copyWith(isPublic: isPublic);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }    
} 