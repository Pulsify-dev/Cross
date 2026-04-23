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
    final trackData = json['track_id'] ?? json['track'];
    if (trackData == null || trackData is! Map<String, dynamic>) {
      throw Exception('Missing or invalid track data in history entry');
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
