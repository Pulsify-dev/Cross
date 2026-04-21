import '../models/track.dart';
import '../models/history_entry.dart';
import '../models/comment.dart';
import '../models/user.dart';

abstract class TrackService {
  Future<List<Track>> getTrendingTracks({String? genre});
  Future<List<Track>> searchTracks(String query);
  Future<Track?> getTrackById(String id);
  Future<void> likeTrack(String trackId);
  Future<void> unlikeTrack(String trackId);
  Future<List<Track>> getLikedTracks();

  Future<List<Track>> getActivityFeed();
  Future<List<HistoryEntry>> getListeningHistory({int page = 1, int limit = 20});
  Future<void> clearListeningHistory();

  Future<List<Comment>> getComments(String trackId);
  Future<void> addComment(
    String trackId,
    String userId,
    String text,
    Duration timestampInTrack, {
    String? parentCommentId,
  });
  Future<void> likeComment(String commentId);
  Future<void> unlikeComment(String commentId);
  Future<void> recordPlay(String trackId, {int durationPlayedMs = 0});
  Future<List<User>> getTrackLikes(String trackId);
  Future<List<Track>> getUserTracks(String userId);
  Future<List<Track>> getArtistTracks(
    String artistId, {
    int page = 1,
    int limit = 20,
  });
  Future<List<double>?> getTrackWaveform(String trackId);
  Future<String?> getStreamUrl(String trackId);
  Future<Map<String, dynamic>> getTrackStatus(String trackId);
  void setCurrentUser(User? user);
}
