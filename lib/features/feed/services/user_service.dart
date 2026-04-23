import '../models/user.dart';

abstract class UserService {
  Future<User?> login(String email, String password);
  Future<User?> register(String username, String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<void> forgotPassword(String email);
  Future<User?> updateProfile(User user);
  Future<User?> updateProfileImage(String filePath);
  Future<List<User>> getSuggestedArtists();
  Future<User?> getPublicProfile(String userId);
  Future<List<User>> getSuggestedUsers({int page = 1, int limit = 20});
}
