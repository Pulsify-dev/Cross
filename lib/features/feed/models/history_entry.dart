import 'track.dart';

/// Represents a single listening history entry returned by the API.
class HistoryEntry {
  final Track track;
  final DateTime playedAt;
  final int durationPlayedMs;
  final bool isCompleted;

  const HistoryEntry({
    required this.track,
    required this.playedAt,
    required this.durationPlayedMs,
    this.isCompleted = false,
  });

  Duration get durationPlayed => Duration(milliseconds: durationPlayedMs);

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    var trackData = json['track_id'] ?? json['track'];
    if (trackData == null || trackData is! Map<String, dynamic>) {
      throw Exception('Missing or invalid track data in history entry');
    }

    // Clone to avoid mutating the original if it's reused elsewhere
    trackData = Map<String, dynamic>.from(trackData);

    // If track data is missing artist name info but the history entry has it, merge it.
    // We check if the existing fields are Maps with actual names, if not, we overwrite with parent data.
    bool hasName(dynamic data) {
      if (data is Map<String, dynamic>) {
        return data['display_name'] != null || data['displayName'] != null || data['username'] != null;
      }
      return false;
    }

    if (trackData['artist_name'] == null && trackData['artistName'] == null) {
      if (!hasName(trackData['artist']) && !hasName(trackData['uploader']) && !hasName(trackData['user'])) {
        if (json['user'] != null) trackData['user'] = json['user'];
        if (json['artist'] != null) trackData['artist'] = json['artist'];
        if (json['uploader'] != null) trackData['uploader'] = json['uploader'];
        if (json['artist_name'] != null) trackData['artist_name'] = json['artist_name'];
        if (json['artistName'] != null) trackData['artistName'] = json['artistName'];
      }
    }

    return HistoryEntry(
      track: Track.fromJson(trackData),
      playedAt: DateTime.parse(json['played_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      durationPlayedMs: (json['duration_played_ms'] ?? 0) is int 
          ? (json['duration_played_ms'] ?? 0) as int 
          : (json['duration_played_ms'] ?? 0).toInt(),
      isCompleted: json['is_completed'] ?? false,
    );
  }
}
