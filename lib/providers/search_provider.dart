import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/feed/models/track.dart';
import '../features/feed/models/user.dart';
import '../features/feed/services/track_service.dart';
import '../features/feed/services/user_service.dart';

class SearchProvider with ChangeNotifier {
  final TrackService _trackService;
  final UserService _userService;

  List<Track> _searchResults = [];
  List<User> _userSearchResults = [];
  List<String> _trackHistory = [];
  List<String> _userHistory = [];
  bool _isLoading = false;
  Timer? _debounce;

  SearchProvider(this._trackService, this._userService);

  List<Track> get searchResults => _searchResults;
  List<User> get userSearchResults => _userSearchResults;
  List<String> get trackHistory => List.unmodifiable(_trackHistory);
  List<String> get userHistory => List.unmodifiable(_userHistory);
  bool get isLoading => _isLoading;

  void search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _searchResults = [];
        _userSearchResults = [];
        notifyListeners();
        return;
      }

      _setLoading(true);
      try {
        final tracksFuture = _trackService.searchTracks(query);
        final usersFuture = _userService.searchUsers(query);

        final results = await Future.wait([tracksFuture, usersFuture]);
        _searchResults = results[0] as List<Track>;
        _userSearchResults = results[1] as List<User>;
        notifyListeners();
      } catch (e) {
        _searchResults = [];
        _userSearchResults = [];
      } finally {
        _setLoading(false);
      }
    });
  }

  /// Call this when a track from results is played or opened.
  void recordTrackSearch(String query) {
    final q = query.trim();
    if (q.isEmpty || _searchResults.isEmpty) return;
    _addTo(_trackHistory, q);
    notifyListeners();
  }

  /// Call this when a user profile from results is opened.
  void recordUserSearch(String query) {
    final q = query.trim();
    if (q.isEmpty || _userSearchResults.isEmpty) return;
    _addTo(_userHistory, q);
    notifyListeners();
  }

  void _addTo(List<String> history, String query) {
    if (query.isEmpty) return;
    history.remove(query);
    history.insert(0, query);
    if (history.length > 20) history.removeRange(20, history.length);
  }

  // ── Track history ──────────────────────────────────────────────────────────
  void removeFromTrackHistory(String query) {
    _trackHistory.remove(query);
    notifyListeners();
  }

  void clearTrackHistory() {
    _trackHistory.clear();
    notifyListeners();
  }

  // ── User history ───────────────────────────────────────────────────────────
  void removeFromUserHistory(String query) {
    _userHistory.remove(query);
    notifyListeners();
  }

  void clearUserHistory() {
    _userHistory.clear();
    notifyListeners();
  }

  Future<User?> getPublicProfile(String userId) async {
    return await _userService.getPublicProfile(userId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
