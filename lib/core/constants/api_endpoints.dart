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
  static String followers(String userId, {int? page, int? limit}) =>
      _withPagination('/users/$userId/followers', page: page, limit: limit);
  static String following(String userId, {int? page, int? limit}) =>
      _withPagination('/users/$userId/following', page: page, limit: limit);

  static String suggestedUsers({int page = 1, int limit = 20}) =>
      _withPagination('/users/me/suggested', page: page, limit: limit);

  static String followUser(String userId) => '/users/$userId/follow';
  static String relationshipStatus(String userId) =>
      '/users/$userId/relationship';
  static String mutualFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) => _withPagination(
    '/users/$userId/mutual-followers',
    page: page,
    limit: limit,
  );

  static String blockedUsers({int page = 1, int limit = 20}) =>
      _withPagination('/users/me/blocked', page: page, limit: limit);

  static String blockUser(String userId) => '/users/$userId/block';
  static String updateBlockReason(String userId) => blockUser(userId);

  static const String tracks = '/tracks';

  static String trackById(String trackId) => '/tracks/$trackId';
  static String trackStatus(String trackId) => '/tracks/$trackId/status';
  static String trackMetadata(String trackId) => trackById(trackId);
  static String trackDelete(String trackId) => trackById(trackId);
  static String trackArtwork(String trackId) => '/tracks/$trackId/artwork';
  static String trackWaveform(String trackId) => '/tracks/$trackId/waveform';
  static String artistTracks(String artistId, {int page = 1, int limit = 20}) =>
      '/artists/$artistId/tracks?page=$page&limit=$limit';

  static String _withPagination(String base, {int? page, int? limit}) {
    if (page == null && limit == null) {
      return base;
    }

    final params = <String>[];
    if (page != null) params.add('page=$page');
    if (limit != null) params.add('limit=$limit');

    return '$base?${params.join('&')}';
  }

  static const String trendingTracks = '/tracks/trending';
  static const String activityFeed = '/tracks/feed';
  static const String listeningHistory = '/users/me/history';
  static const String likedTracks = '/users/me/likes';
}
