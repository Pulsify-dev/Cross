import 'package:flutter/foundation.dart';
import '../features/feed/models/comment.dart';
import '../features/feed/models/user.dart';
import '../features/feed/services/track_service.dart';

class EngagementProvider with ChangeNotifier {
  final TrackService _trackService;
  List<Comment> _comments = [];
  List<User> _trackLikes = [];
  List<User> _trackReposts = [];
  List<Comment> _commentReplies = [];
  int _commentsCount = 0;
  bool _isLoading = false;
  String? _error;

  EngagementProvider(this._trackService);

  List<Comment> get comments => _comments;
  List<User> get trackLikes => _trackLikes;
  List<User> get trackReposts => _trackReposts;
  List<Comment> get commentReplies => _commentReplies;
  int get commentsCount => _commentsCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchComments(String trackId) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _trackService.getComments(trackId);
      _comments = result.comments;
      _commentsCount = result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCommentsCount(String trackId) async {
    try {
      final result = await _trackService.getComments(trackId);
      _commentsCount = result.total;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching comments count: $e');
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

  Future<void> fetchTrackReposts(String trackId) async {
    _setLoading(true);
    _error = null;
    try {
      _trackReposts = await _trackService.getTrackReposts(trackId);
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

  Future<void> fetchCommentReplies(String commentId) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _trackService.getCommentReplies(commentId);
      _commentReplies = result.replies;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Returns replies list directly for inline display per comment.
  Future<List<Comment>> fetchCommentRepliesById(String commentId) async {
    try {
      final result = await _trackService.getCommentReplies(commentId);
      return result.replies;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateComment(String trackId, String commentId, String text) async {
    try {
      await _trackService.updateComment(commentId, text);
      await fetchComments(trackId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteComment(String trackId, String commentId) async {
    try {
      await _trackService.deleteComment(commentId);
      await fetchComments(trackId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Silently delete a comment without refreshing the comment list.
  Future<void> deleteCommentOnly(String commentId) async {
    try {
      await _trackService.deleteComment(commentId);
    } catch (e) {
      // Silently ignore if reply already deleted or not found
    }
  }

  /// Adjusts the local comments count by [delta] (use negative to decrement).
  void adjustCommentsCount(int delta) {
    _commentsCount = (_commentsCount + delta).clamp(0, _commentsCount + delta.abs());
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
