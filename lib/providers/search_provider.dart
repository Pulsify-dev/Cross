import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/feed/models/track.dart';
import '../features/feed/services/track_service.dart';

class SearchProvider with ChangeNotifier {
  final TrackService _trackService;
  List<Track> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  SearchProvider(this._trackService);

  List<Track> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  void search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _searchResults = [];
        notifyListeners();
        return;
      }

      _setLoading(true);
      try {
        _searchResults = await _trackService.searchTracks(query);
      } catch (e) {
        _searchResults = [];
      } finally {
        _setLoading(false);
      }
    });
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
