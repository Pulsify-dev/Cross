import '../models/feed_item.dart';
import '../models/track.dart';
import '../models/history_entry.dart';
import '../models/comment.dart';
import '../models/user.dart';

abstract class TrackService {
  Future<List<Track>> getTrendingTracks({
    String? genre,
    int page = 1,
    int limit = 20,
  });
  Future<Track?> getTrackById(String id);
  Future<void> likeTrack(String trackId);
  Future<void> unlikeTrack(String trackId);
  Future<List<Track>> getLikedTracks();
  Future<bool> isTrackLiked(String trackId);

  Future<List<FeedItem>> getFeed({
    int page = 1,
    int limit = 20,
    bool authRequired = true,
  });
  Future<List<HistoryEntry>> getListeningHistory({
    int page = 1,
    int limit = 20,
  });
  Future<void> clearListeningHistory();

  Future<void> repostTrack(String trackId);
  Future<void> unrepostTrack(String trackId);
  Future<bool> isTrackReposted(String trackId);
  Future<List<User>> getTrackReposts(String trackId);

  Future<({List<Comment> comments, int total})> getComments(String trackId);
  Future<void> addComment(
    String trackId,
    String userId,
    String text,
    Duration timestampInTrack, {
    String? parentCommentId,
  });
  Future<void> updateComment(String commentId, String text);
  Future<void> deleteComment(String commentId);
  Future<({List<Comment> replies, int total})> getCommentReplies(
    String commentId,
  );

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
}
