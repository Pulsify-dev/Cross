import '../../../core/services/api_service.dart';
import '../models/user.dart';
import 'user_service.dart';

class ApiUserService implements UserService {
  final ApiService _apiService;

  ApiUserService(this._apiService);

  @override
  Future<User?> getPublicProfile(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId');
      if (response != null) {
        if (response['data'] != null) {
          return User.fromJson(response['data']);
        }
        return User.fromJson(response);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<List<User>> getSuggestedUsers({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        '/users/me/suggested?page=$page&limit=$limit',
        authRequired: true,
      );

      if (response == null) return [];

      if (response is List) {
        return response.map((data) => User.fromJson(data)).toList();
      }

      final List? list =
          response['suggestedUsers'] ??
          response['users'] ??
          (response['data'] is List ? response['data'] : null) ??
          (response['data'] is Map
              ? (response['data']['suggestedUsers'] ??
                    response['data']['users'])
              : null);

      if (list != null) {
        return list.map((data) => User.fromJson(data)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  @override
  Future<User?> login(String email, String password) async => null;

  @override
  Future<User?> register(
    String username,
    String email,
    String password,
  ) async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<User?> updateProfile(User user) async => null;

  @override
  Future<User?> updateProfileImage(String filePath) async => null;
}
