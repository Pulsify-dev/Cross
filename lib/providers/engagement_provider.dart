import 'package:flutter/foundation.dart';
import '../features/feed/models/comment.dart';
import '../features/feed/models/user.dart';
import '../features/feed/services/track_service.dart';

class EngagementProvider with ChangeNotifier {
  final TrackService _trackService;
  List<Comment> _comments = [];
  List<User> _trackLikes = [];
  bool _isLoading = false;
  String? _error;

  EngagementProvider(this._trackService);

  List<Comment> get comments => _comments;
  List<User> get trackLikes => _trackLikes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchComments(String trackId) async {
    _setLoading(true);
    _error = null;
    try {
      _comments = await _trackService.getComments(trackId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTrackLikes(String trackId) async {
    _setLoading(true);
    _error = null;
    try {
      _trackLikes = await _trackService.getTrackLikes(trackId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addComment(
    String trackId,
    String userId,
    String text,
    Duration timestamp, {
    String? parentCommentId,
  }) async {
    try {
      await _trackService.addComment(
        trackId,
        userId,
        text,
        timestamp,
        parentCommentId: parentCommentId,
      );
      // Refresh comments locally (mock)
      await fetchComments(trackId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleCommentLike(String trackId, Comment comment) async {
    try {
      if (comment.isLiked) {
        await _trackService.unlikeComment(comment.id);
      } else {
        await _trackService.likeComment(comment.id);
      }
      await fetchComments(trackId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
