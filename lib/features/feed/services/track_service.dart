import '../models/track.dart';
import '../models/comment.dart';
import '../models/user.dart';

abstract class TrackService {
  Future<List<Track>> getTrendingTracks({String? genre});
  Future<List<Track>> searchTracks(String query);
  Future<Track?> getTrackById(String id);
  Future<void> likeTrack(String trackId);
  Future<void> unlikeTrack(String trackId);
  Future<List<Track>> getLikedTracks();

  // New methods for Ali's modules
  Future<List<Track>> getActivityFeed();
  Future<List<Track>> getListeningHistory();
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
  Future<void> recordPlay(String trackId);
  Future<List<User>> getTrackLikes(String trackId);
  Future<List<User>> getSuggestedArtists();
  Future<List<Track>> getUserTracks(String userId);
  void setCurrentUser(User? user);
}
