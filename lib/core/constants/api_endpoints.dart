class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyEmail = '/auth/verify-email';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static const String profile = '/users/me';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/users/me/avatar';
  
  static String followers(String userId) => '/users/$userId/followers';
  static String following(String userId) => '/users/$userId/following';

  static const String tracks = '/tracks';

  static String trackById(String trackId) => '/tracks/$trackId';
  static String trackStatus(String trackId) => '/tracks/$trackId/status';
  static String trackMetadata(String trackId) => trackById(trackId);
  static String trackDelete(String trackId) => trackById(trackId);
  static String trackArtwork(String trackId) => '/tracks/$trackId/artwork';
  static String trackWaveform(String trackId) => '/tracks/$trackId/waveform';
  static String artistTracks(
    String artistId, {
    int page = 1,
    int limit = 20,
  }) => '/artists/$artistId/tracks?page=$page&limit=$limit';
}