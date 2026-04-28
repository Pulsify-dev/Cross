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

  @override
  Future<void> followUser(String userId) async {
<<<<<<< HEAD
    await _apiService.post('/users/$userId/follow',{}, authRequired: true);
=======
    await _apiService.post(
      '/users/$userId/follow',
      body: {},
      authRequired: true,
    );
>>>>>>> origin/develop
  }

  @override
  Future<void> unfollowUser(String userId) async {
    await _apiService.delete('/users/$userId/follow', authRequired: true);
  }
  @override
  Future<List<User>> getSuggestedUsers({int? limit, int? page}) async {
    return [];
  }
}
