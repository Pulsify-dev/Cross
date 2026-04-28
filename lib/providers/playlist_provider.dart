import 'package:flutter/material.dart';
import 'package:cross/features/playlists/models/playlist_model.dart';
import 'package:cross/features/playlists/services/playlist_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _service;
  final List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _errorMessage;

  PlaylistProvider(this._service);
  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPlaylists(String token) async {
    if (token.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
     // _playlists = await _service.getPlaylists(token);
    } catch (e) {
      _errorMessage = "Connection issues: 502 Bad Gateway.";
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
        _playlists.insert(0, newPlaylist as Playlist);
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