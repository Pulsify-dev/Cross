import '../models/search_models.dart';

abstract class SearchService {
  Future<GlobalSearchResponse> search(String query, {int limit = 20, int offset = 0});
  Future<List<SearchSuggestion>> getSuggestions(String query, {int limit = 10});
}
