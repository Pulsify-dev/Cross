import 'package:flutter/material.dart';
import '../models/playlist_model.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  // 1. Create with Privacy Logic
  void addPlaylist(String name, bool isPublic) {
    final String token = isPublic ? '' : "PULSIFY-${DateTime.now().millisecondsSinceEpoch}";
    _playlists.add(Playlist(
      id: DateTime.now().toString(),
      name: name,
      isPublic: isPublic,
      secretToken: token,
    ));
    notifyListeners();
  }

  // 2. Delete (The 'D' in CRUD)
  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // 3. Sequencing (Drag and Drop)
  void reorderTracks(String playlistId, int oldIndex, int newIndex) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (newIndex > oldIndex) newIndex -= 1;
    final String movedTrack = playlist.tracks.removeAt(oldIndex);
    playlist.tracks.insert(newIndex, movedTrack);
    notifyListeners();
  }

  void addTrackToPlaylist(String playlistId, String trackName) {
  final index = playlists.indexWhere((p) => p.id == playlistId);
  if (index != -1) {
    playlists[index].tracks.add(trackName);
    notifyListeners(); // This makes the song appear on the Details screen immediately!
  }
}

  void removeTrackFromPlaylist(String playlistId, String trackName) {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      playlists[index].tracks.remove(trackName);
      notifyListeners();
    }
  }
}