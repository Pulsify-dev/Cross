import 'package:cross/core/constants/api_endpoints.dart';
import 'package:cross/core/services/api_service.dart';
import 'package:cross/features/social/models/mutual_follower_model.dart';
import 'package:cross/features/social/models/public_profile_model.dart';
import 'package:cross/features/social/models/relationship_status_model.dart';
import 'package:cross/features/social/models/social_user_list_response.dart';

abstract class SocialService {
	void setCurrentUser(String userId);
	Future<PublicProfileModel> getPublicProfile(String userId);
	Future<RelationshipStatusModel> getRelationshipStatus(String userId);
	Future<SocialUserListResponse> getMutualFollowers(
		String userId, {
		int page = 1,
		int limit = 20,
	});
	Future<SocialUserListResponse> getFollowers(
		String userId, {
		int page = 1,
		int limit = 20,
	});
	Future<SocialUserListResponse> getFollowing(
		String userId, {
		int page = 1,
		int limit = 20,
	});
	Future<SocialUserListResponse> getSuggestedUsers({
		int page = 1,
		int limit = 20,
	});
	Future<SocialUserListResponse> getBlockedUsers({
		int page = 1,
		int limit = 20,
	});
	Future<RelationshipStatusModel> followUser(String userId);
	Future<RelationshipStatusModel> unfollowUser(String userId);
	Future<RelationshipStatusModel> blockUser(String userId, {String? reason});
	Future<RelationshipStatusModel> unblockUser(String userId);
}

class MockSocialService implements SocialService {
	MockSocialService({ApiService? apiService})
			: _apiService = apiService ?? ApiService();

	final ApiService _apiService;

	static final Map<String, _MockUser> _users = {
		'u1': _MockUser(
			id: 'u1',
			username: 'alexrivera',
			displayName: 'Alex Rivera',
			bio: 'Night drives, synths, and city lights.',
			avatarUrl: 'https://i.pravatar.cc/150?img=32',
			coverUrl: 'https://picsum.photos/seed/cover_u1/900/320',
			isVerified: true,
			favoriteGenres: ['Electronic', 'Synthwave', 'House'],
			uploadedTracks: ['After Hours', 'Blue Skyline', 'Zero Gravity'],
			playlists: ['Late Night Vibes', 'Studio Cuts'],
		),
		'u2': _MockUser(
			id: 'u2',
			username: 'jordansmith',
			displayName: 'Jordan Smith',
			bio: 'Indie singer-songwriter.',
			avatarUrl: 'https://i.pravatar.cc/150?img=12',
			coverUrl: 'https://picsum.photos/seed/cover_u2/900/320',
			isVerified: false,
			favoriteGenres: ['Indie Pop', 'Lo-fi'],
			uploadedTracks: ['Spring Blossom', 'Sunday Coffee'],
			playlists: ['Rainy Day', 'Acoustic'],
		),
		'u3': _MockUser(
			id: 'u3',
			username: 'sarahchen',
			displayName: 'Sarah Chen',
			bio: 'Beats and bass.',
			avatarUrl: 'https://i.pravatar.cc/150?img=5',
			coverUrl: 'https://picsum.photos/seed/cover_u3/900/320',
			isVerified: false,
			favoriteGenres: ['Hip-Hop', 'Trap'],
			uploadedTracks: ['Urban Dreams'],
			playlists: ['Workout'],
		),
		'u4': _MockUser(
			id: 'u4',
			username: 'marcuswright',
			displayName: 'Marcus Wright',
			bio: 'Live sessions and jam takes.',
			avatarUrl: 'https://i.pravatar.cc/150?img=15',
			coverUrl: 'https://picsum.photos/seed/cover_u4/900/320',
			isVerified: false,
			favoriteGenres: ['Rock', 'Jazz'],
			uploadedTracks: ['Broken Compass', 'Midnight Jam'],
			playlists: ['Guitar Riffs'],
		),
		'u5': _MockUser(
			id: 'u5',
			username: 'rileytaylor',
			displayName: 'Riley Taylor',
			bio: 'Ambient textures and ocean sounds.',
			avatarUrl: 'https://i.pravatar.cc/150?img=20',
			coverUrl: 'https://picsum.photos/seed/cover_u5/900/320',
			isVerified: false,
			favoriteGenres: ['Ambient', 'Chillwave'],
			uploadedTracks: ['Ocean Waves'],
			playlists: ['Sleep Focus'],
		),
	};

	static final Map<String, Set<String>> _followingByUser = {
		'me': {'u1', 'u4'},
		'u1': {'me', 'u2', 'u5'},
		'u2': {'u1'},
		'u3': {'me'},
		'u4': {'u1'},
		'u5': {'u1', 'me'},
	};

	static final Map<String, Set<String>> _blockedByUser = {
		'me': {'u3'},
		'u4': {'me'},
	};

	String _currentUserId = 'me';

	@override
	void setCurrentUser(String userId) {
		_currentUserId = userId.trim().isEmpty ? 'me' : userId.trim();
		_followingByUser.putIfAbsent(_currentUserId, () => <String>{});
		_blockedByUser.putIfAbsent(_currentUserId, () => <String>{});
	}

	@override
	Future<PublicProfileModel> getPublicProfile(String userId) async {
		try {
			final response = await _apiService.get(
				ApiEndpoints.profile(userId),
				authRequired: true,
			);

			if (response is! Map<String, dynamic>) {
				throw const ApiException('Invalid public profile response');
			}

			final payload = _extractPublicProfilePayload(response);
			final normalized = _normalizePublicProfilePayload(payload);
			return PublicProfileModel.fromJson(normalized);
		} on ApiException catch (e) {
			if (e.statusCode == 403) {
				throw const ApiException(
					'Profile is not accessible.',
					statusCode: 403,
				);
			}

			if (e.statusCode == 404) {
				throw const ApiException(
					'Profile is unavailable.',
					statusCode: 404,
				);
			}

			rethrow;
		}
	}

	@override
	Future<RelationshipStatusModel> getRelationshipStatus(String userId) async {
		if (_users.containsKey(userId)) {
			return _buildRelationship(userId);
		}

		final response = await _apiService.get(
			ApiEndpoints.relationshipStatus(userId),
			authRequired: true,
		);

		final relation = _tryParseRelationship(response);
		if (relation != null) {
			return relation;
		}

		throw const ApiException('Invalid relationship status response');
	}

	@override
	Future<SocialUserListResponse> getMutualFollowers(
		String userId, {
		int page = 1,
		int limit = 20,
	}) async {
		if (_users.containsKey(userId)) {
			final targetFollowers = _followersOf(userId);
			final currentFollowers = _followersOf(_currentUserId);
			final mutualIds = targetFollowers.intersection(currentFollowers).toList();
			return _buildUserListResponse(mutualIds, page: page, limit: limit, subtitle: 'Mutual follower');
		}

		final response = await _apiService.get(
			ApiEndpoints.mutualFollowers(userId, page: page, limit: limit),
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid mutual followers response');
		}

		final data = response['data'];
		if (data is! Map<String, dynamic>) {
			throw const ApiException('Invalid mutual followers payload');
		}

		final normalized = {
			...data,
			'users': data['mutualFollowers'],
		};

		return SocialUserListResponse.fromJson(normalized);
	}

	@override
	Future<SocialUserListResponse> getFollowers(
		String userId, {
		int page = 1,
		int limit = 20,
	}) async {
		if (_users.containsKey(userId)) {
			final ids = _followersOf(userId).toList();
			return _buildUserListResponse(ids, page: page, limit: limit, subtitle: 'Follows this user');
		}

		final response = await _apiService.get(
			ApiEndpoints.followers(userId, page: page, limit: limit),
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid followers response');
		}

		final data = response['data'];
		if (data is! Map<String, dynamic>) {
			throw const ApiException('Invalid followers payload');
		}

		final normalized = {
			...data,
			'users': (data['followers'] as List?)
					?.whereType<Map<String, dynamic>>()
					.map((user) => {
						...user,
						// Followers list means these users follow the current viewer.
						'isFollowedBy': true,
						// Preserve server relationship flags when available.
						if (user.containsKey('isFollowing'))
							'isFollowing': user['isFollowing'],
						if (!user.containsKey('isFollowing') && user.containsKey('is_following'))
							'is_following': user['is_following'],
					})
					.toList(),
		};

		return SocialUserListResponse.fromJson(normalized);
	}

	@override
	Future<SocialUserListResponse> getFollowing(
		String userId, {
		int page = 1,
		int limit = 20,
	}) async {
		if (_users.containsKey(userId)) {
			final ids = _followingByUser[userId]?.toList() ?? const <String>[];
			return _buildUserListResponse(ids, page: page, limit: limit, subtitle: 'Following');
		}

		final response = await _apiService.get(
			ApiEndpoints.following(userId, page: page, limit: limit),
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid following response');
		}

		final data = response['data'];
		if (data is! Map<String, dynamic>) {
			throw const ApiException('Invalid following payload');
		}

		final normalized = {
			...data,
			'users': (data['following'] as List?)
					?.whereType<Map<String, dynamic>>()
					.map((user) => {
						...user,
						'isFollowing': true,
					})
					.toList(),
		};

		return SocialUserListResponse.fromJson(normalized);
	}

	@override
	Future<SocialUserListResponse> getSuggestedUsers({
		int page = 1,
		int limit = 20,
	}) async {
		final response = await _apiService.get(
			ApiEndpoints.suggestedUsers(page: page, limit: limit),
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid suggested users response');
		}

		final data = response['data'];
		if (data is! Map<String, dynamic>) {
			throw const ApiException('Invalid suggested users payload');
		}

		final usersRaw = data['suggestedUsers'];
		final normalized = {
			...data,
			'users': usersRaw,
		};

		return SocialUserListResponse.fromJson(normalized);
	}

	@override
	Future<SocialUserListResponse> getBlockedUsers({
		int page = 1,
		int limit = 20,
	}) async {
		final response = await _apiService.get(
			ApiEndpoints.blockedUsers(page: page, limit: limit),
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid blocked users response');
		}

		final data = response['data'];
		if (data is! Map<String, dynamic>) {
			throw const ApiException('Invalid blocked users payload');
		}

		final normalized = {
			...data,
			'users': data['blockedUsers'],
		};

		return SocialUserListResponse.fromJson(normalized);
	}

	@override
	Future<RelationshipStatusModel> followUser(String userId) async {
		if (_users.containsKey(userId)) {
			final relation = _buildRelationship(userId);
			if (relation.isUnavailable) {
				throw const ApiException('Cannot follow this user.');
			}

			_followingByUser.putIfAbsent(_currentUserId, () => <String>{}).add(userId);
			return _buildRelationship(userId);
		}

		final response = await _apiService.post(
			ApiEndpoints.followUser(userId),
			authRequired: true,
		);

		final relation = _tryParseRelationship(response);
		if (relation != null) {
			return relation;
		}

		return getRelationshipStatus(userId);
	}

	@override
	Future<RelationshipStatusModel> unfollowUser(String userId) async {
		if (_users.containsKey(userId)) {
			_followingByUser.putIfAbsent(_currentUserId, () => <String>{}).remove(userId);
			return _buildRelationship(userId);
		}

		final response = await _apiService.delete(
			ApiEndpoints.followUser(userId),
			authRequired: true,
		);

		final relation = _tryParseRelationship(response);
		if (relation != null) {
			return relation;
		}

		return getRelationshipStatus(userId);
	}

	@override
	Future<RelationshipStatusModel> blockUser(String userId, {String? reason}) async {
		if (_users.containsKey(userId)) {
			_blockedByUser.putIfAbsent(_currentUserId, () => <String>{}).add(userId);
			_followingByUser.putIfAbsent(_currentUserId, () => <String>{}).remove(userId);
			_followingByUser.putIfAbsent(userId, () => <String>{}).remove(_currentUserId);
			return _buildRelationship(userId);
		}

		await _apiService.post(
			ApiEndpoints.blockUser(userId),
			body: {
				if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
			},
			authRequired: true,
		);

		return const RelationshipStatusModel(
			isFollowing: false,
			isFollowedBy: false,
			isMutual: false,
			isBlockedByMe: true,
			isBlockedByThem: false,
		);
	}

	@override
	Future<RelationshipStatusModel> unblockUser(String userId) async {
		if (_users.containsKey(userId)) {
			_blockedByUser.putIfAbsent(_currentUserId, () => <String>{}).remove(userId);
			return _buildRelationship(userId);
		}

		await _apiService.delete(
			ApiEndpoints.blockUser(userId),
			authRequired: true,
		);

		final relation = await getRelationshipStatus(userId);
		return relation.copyWith(isBlockedByMe: false);
	}

	Map<String, dynamic> _extractPublicProfilePayload(Map<String, dynamic> response) {
		final data = response['data'];

		if (data is Map<String, dynamic>) {
			final nestedUser = data['user'];
			if (nestedUser is Map<String, dynamic>) {
				return {
					...data,
					...nestedUser,
				};
			}

			final nestedProfile = data['profile'];
			if (nestedProfile is Map<String, dynamic>) {
				return {
					...data,
					...nestedProfile,
				};
			}

			final nestedPublicProfile = data['publicProfile'];
			if (nestedPublicProfile is Map<String, dynamic>) {
				return {
					...data,
					...nestedPublicProfile,
				};
			}

			return data;
		}

		if (response['user'] is Map<String, dynamic>) {
			return {
				...response,
				...(response['user'] as Map<String, dynamic>),
			};
		}

		if (response.containsKey('_id') || response.containsKey('id')) {
			return response;
		}

		throw const ApiException('Invalid public profile payload');
	}

	Map<String, dynamic> _normalizePublicProfilePayload(Map<String, dynamic> raw) {
		final socialCounts = raw['socialCounts'];
		final socialCountsMap =
				socialCounts is Map<String, dynamic> ? socialCounts : const <String, dynamic>{};

		final counts = raw['counts'];
		final countsMap = counts is Map<String, dynamic> ? counts : const <String, dynamic>{};

		return {
			'id': raw['id'] ?? raw['_id'] ?? '',
			'username': raw['username'] ?? '',
			'displayName': raw['displayName'] ?? raw['display_name'] ?? '',
			'bio': raw['bio'] ?? '',
			'avatarUrl': raw['avatarUrl'] ?? raw['avatar_url'] ?? '',
			'coverUrl': raw['coverUrl'] ?? raw['cover_url'] ?? '',
			'isVerified': raw['isVerified'] ?? raw['is_verified'] ?? false,
			'followersCount': _firstInt(
				[
					raw['followersCount'],
					raw['followers_count'],
					socialCountsMap['followersCount'],
					socialCountsMap['followers_count'],
					countsMap['followersCount'],
					countsMap['followers_count'],
				],
				fallback: 0,
			),
			'followingCount': _firstInt(
				[
					raw['followingCount'],
					raw['following_count'],
					socialCountsMap['followingCount'],
					socialCountsMap['following_count'],
					countsMap['followingCount'],
					countsMap['following_count'],
				],
				fallback: 0,
			),
			'mutualFollowersCount': _firstInt(
				[
					raw['mutualFollowersCount'],
					raw['mutual_followers_count'],
					socialCountsMap['mutualFollowersCount'],
					socialCountsMap['mutual_followers_count'],
					countsMap['mutualFollowersCount'],
					countsMap['mutual_followers_count'],
				],
				fallback: 0,
			),
			'trackCount': _firstInt(
				[
					raw['trackCount'],
					raw['track_count'],
					socialCountsMap['trackCount'],
					socialCountsMap['track_count'],
					countsMap['trackCount'],
					countsMap['track_count'],
				],
				fallback: 0,
			),
			'playlistCount': _firstInt(
				[
					raw['playlistCount'],
					raw['playlist_count'],
					socialCountsMap['playlistCount'],
					socialCountsMap['playlist_count'],
					countsMap['playlistCount'],
					countsMap['playlist_count'],
				],
				fallback: 0,
			),
			'favoriteGenres': _toStringList(raw['favoriteGenres'] ?? raw['favorite_genres']),
			'uploadedTracks': _toStringList(
				raw['uploadedTracks'] ?? raw['uploaded_tracks'] ?? raw['tracks'],
			),
			'playlists': _toStringList(raw['playlists']),
		};
	}

	int _firstInt(List<dynamic> values, {required int fallback}) {
		for (final value in values) {
			if (value is int) return value;
			if (value is num) return value.toInt();
			if (value == null) continue;
			final parsed = int.tryParse(value.toString());
			if (parsed != null) return parsed;
		}

		return fallback;
	}

	List<String> _toStringList(dynamic value) {
		if (value is! List) return const <String>[];

		final result = <String>[];
		for (final item in value) {
			if (item == null) continue;
			if (item is String) {
				final trimmed = item.trim();
				if (trimmed.isNotEmpty) result.add(trimmed);
				continue;
			}

			if (item is Map<String, dynamic>) {
				final candidate =
						item['title'] ?? item['name'] ?? item['display_name'] ?? item['username'];
				if (candidate != null && candidate.toString().trim().isNotEmpty) {
					result.add(candidate.toString().trim());
					continue;
				}
			}

			final fallback = item.toString().trim();
			if (fallback.isNotEmpty) result.add(fallback);
		}

		return result;
	}

	RelationshipStatusModel _buildRelationship(String targetUserId) {
		final myFollowing = _followingByUser[_currentUserId] ?? <String>{};
		final targetFollowing = _followingByUser[targetUserId] ?? <String>{};
		final myBlocked = _blockedByUser[_currentUserId] ?? <String>{};
		final targetBlocked = _blockedByUser[targetUserId] ?? <String>{};

		final isFollowing = myFollowing.contains(targetUserId);
		final isFollowedBy = targetFollowing.contains(_currentUserId);
		final isBlockedByMe = myBlocked.contains(targetUserId);
		final isBlockedByThem = targetBlocked.contains(_currentUserId);

		return RelationshipStatusModel(
			isFollowing: isFollowing,
			isFollowedBy: isFollowedBy,
			isMutual: isFollowing && isFollowedBy,
			isBlockedByMe: isBlockedByMe,
			isBlockedByThem: isBlockedByThem,
		);
	}

	Set<String> _followersOf(String userId) {
		final followers = <String>{};
		for (final entry in _followingByUser.entries) {
			if (entry.value.contains(userId)) followers.add(entry.key);
		}
		return followers;
	}

	SocialUserListResponse _buildUserListResponse(
		List<String> ids, {
		required int page,
		required int limit,
		required String subtitle,
	}) {
		final deduped = ids.toSet().toList();
		final start = ((page - 1) * limit).clamp(0, deduped.length);
		final end = (start + limit).clamp(0, deduped.length);
		final pageIds = deduped.sublist(start, end);

		final users = pageIds
				.where((id) => _users.containsKey(id))
				.map((id) {
					final user = _users[id]!;
					final relation = _buildRelationship(id);
					return MutualFollowerModel(
						id: user.id,
						username: user.username,
						displayName: user.displayName,
						avatarUrl: user.avatarUrl,
						subtitle: subtitle,
						isFollowing: relation.isFollowing,
						isFollowedBy: relation.isFollowedBy,
					);
				})
				.toList();

		return SocialUserListResponse(
			users: users,
			page: page,
			limit: limit,
			total: deduped.length,
			hasMore: end < deduped.length,
		);
	}

	RelationshipStatusModel? _tryParseRelationship(dynamic response) {
		if (response is! Map<String, dynamic>) {
			return null;
		}

		final data = response['data'];
		if (data is Map<String, dynamic> && _hasRelationshipFields(data)) {
			return RelationshipStatusModel.fromJson(data);
		}

		if (_hasRelationshipFields(response)) {
			return RelationshipStatusModel.fromJson(response);
		}

		return null;
	}

	bool _hasRelationshipFields(Map<String, dynamic> json) {
		return json.containsKey('isFollowing') ||
				json.containsKey('is_following') ||
				json.containsKey('isFollowedBy') ||
				json.containsKey('is_followed_by') ||
				json.containsKey('isMutual') ||
				json.containsKey('is_mutual') ||
				json.containsKey('isBlockedByMe') ||
				json.containsKey('is_blocked_by_me') ||
				json.containsKey('isBlockedByThem') ||
				json.containsKey('is_blocked_by_them');
	}
}

class _MockUser {
	const _MockUser({
		required this.id,
		required this.username,
		required this.displayName,
		required this.bio,
		required this.avatarUrl,
		required this.coverUrl,
		required this.isVerified,
		required this.favoriteGenres,
		required this.uploadedTracks,
		required this.playlists,
	});

	final String id;
	final String username;
	final String displayName;
	final String bio;
	final String avatarUrl;
	final String coverUrl;
	final bool isVerified;
	final List<String> favoriteGenres;
	final List<String> uploadedTracks;
	final List<String> playlists;
}
