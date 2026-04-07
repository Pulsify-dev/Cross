class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyEmail = '/auth/verify-email';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static String profile(String userId) => '/users/$userId';
  static String editProfile(String userId) => '/users/$userId/edit';
  static String followers(String userId) => '/users/$userId/followers';
  static String following(String userId) => '/users/$userId/following';

  static const String tracks = '/tracks';

  static String trackById(String trackId) => '/tracks/$trackId';
  static String trackStatus(String trackId) => '/tracks/$trackId/status';
  static String trackMetadata(String trackId) => trackById(trackId);
  static String trackDelete(String trackId) => trackById(trackId);
  static String trackArtwork(String trackId) => '/tracks/$trackId/artwork';
  static String trackWaveform(String trackId) => '/tracks/$trackId/waveform';
  static String artistTracks(String artistId, {int page = 1, int limit = 20}) =>
      '/artists/$artistId/tracks?page=$page&limit=$limit';

  static const String trendingTracks = '/tracks/trending';
  static const String activityFeed = '/tracks/feed';
  static const String listeningHistory = '/users/me/history';
  static const String likedTracks = '/users/me/likes';
}
