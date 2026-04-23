class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static String socialLogin(String provider) => '/auth/social/$provider';
  static const String verifyEmail = '/auth/verify-email';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String resendVerification = '/auth/resend-verification';
  static const String myProfile = '/users/me';
  static const String uploadAvatar = '/users/me/avatar';
  static const String changePassword = '/users/me/password';
  static String globalSearch(String query, {int limit = 20, int offset = 0}) =>
      '/search?q=${Uri.encodeQueryComponent(query)}&limit=$limit&offset=$offset';
  static String searchSuggestions(String query, {int limit = 10}) =>
      '/search/suggestions?q=${Uri.encodeQueryComponent(query)}&limit=$limit';
  static const String confirmEmailChange = '/users/confirm-email-change';
  static String publicProfile(String userId) => '/users/$userId';
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
  static String trackStreamUrl(String trackId) => '/tracks/$trackId/stream-url';
  static String artistTracks(String artistId, {int page = 1, int limit = 20}) =>
      '/artists/$artistId/tracks?page=$page&limit=$limit';

  static String _withPagination(
    String base, {
    int? page,
    int? limit,
    int? skip,
  }) {
    if (page == null && limit == null && skip == null) {
      return base;
    }

    final params = <String>[];
    if (skip != null) {
      params.add('skip=$skip');
    } else if (page != null && limit != null) {
      params.add('skip=${(page - 1) * limit}');
    } else if (page != null) {
      params.add('skip=${(page - 1) * 20}');
    }

    if (limit != null) params.add('limit=$limit');

    return '$base?${params.join('&')}';
  }

  static const String trendingTracks = '/trending';
  static const String charts = '/charts';
  static const String feed = '/feed';

  static String conversations({int page = 1, int limit = 20}) =>
      _withPagination('/conversations', page: page, limit: limit);
  static String startConversation() => '/conversations';
  static const String conversationsUnreadCount = '/conversations/unread-count';
  static String conversationMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) => _withPagination(
    '/conversations/$conversationId/messages',
    page: page,
    limit: limit,
  );
  static String sendMessage(String conversationId) =>
      '/conversations/$conversationId/messages';
  static String markConversationRead(String conversationId) =>
      '/conversations/$conversationId/read';

  static const String listeningHistory = '/users/me/history';
  static const String clearListeningHistory = '/users/me/history';
  static const String likedTracks = '/users/me/likes';
  static String trackRecordPlay(String trackId) => '/tracks/$trackId/play';
  static String trackLike(String trackId) => '/tracks/$trackId/like';
  static String trackLikes(String trackId, {int page = 1, int limit = 20}) =>
      _withPagination('/tracks/$trackId/likes', page: page, limit: limit);
  static String trackIsLiked(String trackId) => '/tracks/$trackId/liked';
  static String trackRepost(String trackId) => '/tracks/$trackId/repost';
  static String trackReposts(String trackId, {int page = 1, int limit = 20}) =>
      _withPagination('/tracks/$trackId/reposts', page: page, limit: limit);
  static String trackIsReposted(String trackId) => '/tracks/$trackId/reposted';
  static String trackComments(String trackId, {int page = 1, int limit = 20}) =>
      _withPagination('/tracks/$trackId/comments', page: page, limit: limit);
  static String commentReplies(
    String commentId, {
    int page = 1,
    int limit = 20,
  }) =>
      _withPagination('/comments/$commentId/replies', page: page, limit: limit);
  static String commentAction(String commentId) => '/comments/$commentId';
}
