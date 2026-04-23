import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/feed/models/track.dart';
import '../features/feed/models/user.dart';
import '../features/feed/models/playlist.dart';
import '../features/feed/services/user_service.dart';
import '../features/search/models/search_models.dart';
import '../features/search/services/search_service.dart';

class SearchProvider with ChangeNotifier {
  final SearchService _searchService;
  final UserService _userService;

  GlobalSearchResponse _searchResponse = GlobalSearchResponse();
  List<SearchSuggestion> _suggestions = [];
  
  final List<String> _searchHistory = [];
  bool _isLoading = false;
  Timer? _suggestionDebounce;

  SearchProvider(this._searchService, this._userService);

  GlobalSearchResponse get searchResponse => _searchResponse;
  List<SearchSuggestion> get suggestions => _suggestions;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  bool get isLoading => _isLoading;

  Future<void> search(String query) async {
    _suggestionDebounce?.cancel();
    
    if (query.isEmpty) {
      _searchResponse = GlobalSearchResponse();
      _suggestions = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _searchResponse = await _searchService.search(query);
      _addToHistory(query);
      notifyListeners();
    } catch (e) {
      _searchResponse = GlobalSearchResponse();
    } finally {
      _setLoading(false);
    }
  }

  void getSuggestions(String query) {
    _suggestionDebounce?.cancel();
    _suggestionDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        _suggestions = [];
        notifyListeners();
        return;
      }

      try {
        _suggestions = await _searchService.getSuggestions(query);
        notifyListeners();
      } catch (e) {
        _suggestions = [];
      }
    });
  }

  void _addToHistory(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _searchHistory.remove(q);
    _searchHistory.insert(0, q);
    if (_searchHistory.length > 20) _searchHistory.removeRange(20, _searchHistory.length);
  }

  void removeFromHistory(String query) {
    _searchHistory.remove(query);
    notifyListeners();
  }

  void clearHistory() {
    _searchHistory.clear();
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
    _suggestionDebounce?.cancel();
    super.dispose();
  }
}
