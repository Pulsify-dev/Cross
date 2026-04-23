import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/search_models.dart';
import 'search_service.dart';

class ApiSearchService implements SearchService {
  final ApiService _apiService;

  ApiSearchService(this._apiService);

  @override
  Future<GlobalSearchResponse> search(String query, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.globalSearch(query, limit: limit, offset: offset),
      );
      if (response != null && response is Map<String, dynamic>) {
        return GlobalSearchResponse.fromJson(response);
      }
    } catch (e) {
      rethrow;
    }
    return GlobalSearchResponse();
  }

  @override
  Future<List<SearchSuggestion>> getSuggestions(String query, {int limit = 10}) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.searchSuggestions(query, limit: limit),
      );
      if (response != null && response is Map<String, dynamic> && response['data'] != null) {
        final data = response['data'] as List;
        return data.map((i) => SearchSuggestion.fromJson(i as Map<String, dynamic>)).toList();
      } else if (response != null && response is List) {
        return response.map((i) => SearchSuggestion.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Don't rethrow for suggestions, just return empty list to avoid UI flicker/error
    }
    return [];
  }
}
