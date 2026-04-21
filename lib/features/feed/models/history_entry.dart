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
}
