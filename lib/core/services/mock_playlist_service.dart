import 'package:cross/features/playlists/models/playlist_model.dart';

class MockPlaylistService {
  Future<List<Playlist>> getPlaylists() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return [
      Playlist(id: '1', name: 'Rock Mix', tracks: ['Song A', 'Song B']),
      Playlist(id: '2', name: 'Study Beats', tracks: ['Song C']),
    ];
  }
}