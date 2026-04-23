export '../../feed/models/track.dart';
export '../../feed/models/user.dart';
export '../../feed/models/playlist.dart';
import '../../feed/models/track.dart';
import '../../feed/models/user.dart';
import '../../feed/models/playlist.dart';

class GlobalSearchResponse {
  final List<Track> tracks;
  final List<User> users;
  final List<Playlist> playlists;

  GlobalSearchResponse({
    this.tracks = const [],
    this.users = const [],
    this.playlists = const [],
  });

  factory GlobalSearchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return GlobalSearchResponse(
      tracks: data['tracks'] != null
          ? (data['tracks'] as List).map((i) => Track.fromJson(i)).toList()
          : [],
      users: data['users'] != null
          ? (data['users'] as List).map((i) => User.fromJson(i)).toList()
          : [],
      playlists: data['playlists'] != null
          ? (data['playlists'] as List).map((i) => Playlist.fromJson(i)).toList()
          : [],
    );
  }

  bool get isEmpty => tracks.isEmpty && users.isEmpty && playlists.isEmpty;
}

class SearchSuggestion {
  final String text;
  final String? type; // e.g. 'track', 'artist', 'playlist'

  SearchSuggestion({required this.text, this.type});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] ?? '',
      type: json['type'],
    );
  }
}
