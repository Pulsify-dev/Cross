import 'package:flutter/foundation.dart';

import 'package:cross/features/social/models/mutual_follower_model.dart';
import 'package:cross/features/social/models/public_profile_model.dart';
import 'package:cross/features/social/models/relationship_status_model.dart';
import 'package:cross/features/social/models/social_user_list_response.dart';
import 'package:cross/features/social/services/social_service.dart';

enum SocialListType {
	followers,
	following,
	mutualFollowers,
	suggested,
	blocked,
}

class SocialProvider extends ChangeNotifier {
	SocialProvider({SocialService? service})
			: _service = service ?? MockSocialService();

	final SocialService _service;

	String _currentUserId = 'me';

	PublicProfileModel? _publicProfile;
	RelationshipStatusModel? _relationshipStatus;
	bool _isLoadingProfile = false;
	bool _isMutatingRelationship = false;
	String? _profileError;

	final Map<SocialListType, List<MutualFollowerModel>> _lists = {
		SocialListType.followers: <MutualFollowerModel>[],
		SocialListType.following: <MutualFollowerModel>[],
		SocialListType.mutualFollowers: <MutualFollowerModel>[],
		SocialListType.suggested: <MutualFollowerModel>[],
		SocialListType.blocked: <MutualFollowerModel>[],
	};

	final Map<SocialListType, bool> _isLoadingList = {
		SocialListType.followers: false,
		SocialListType.following: false,
		SocialListType.mutualFollowers: false,
		SocialListType.suggested: false,
		SocialListType.blocked: false,
	};

	final Map<SocialListType, String?> _listErrors = {
		SocialListType.followers: null,
		SocialListType.following: null,
		SocialListType.mutualFollowers: null,
		SocialListType.suggested: null,
		SocialListType.blocked: null,
	};

	final Map<SocialListType, int> _listTotals = {
		SocialListType.followers: 0,
		SocialListType.following: 0,
		SocialListType.mutualFollowers: 0,
		SocialListType.suggested: 0,
		SocialListType.blocked: 0,
	};

	String get currentUserId => _currentUserId;
	PublicProfileModel? get publicProfile => _publicProfile;
	RelationshipStatusModel? get relationshipStatus => _relationshipStatus;
	bool get isLoadingProfile => _isLoadingProfile;
	bool get isMutatingRelationship => _isMutatingRelationship;
	String? get profileError => _profileError;

	List<MutualFollowerModel> get followers =>
			List.unmodifiable(_lists[SocialListType.followers]!);
	List<MutualFollowerModel> get following =>
			List.unmodifiable(_lists[SocialListType.following]!);
	List<MutualFollowerModel> get mutualFollowers =>
			List.unmodifiable(_lists[SocialListType.mutualFollowers]!);
	List<MutualFollowerModel> get suggestedUsers =>
			List.unmodifiable(_lists[SocialListType.suggested]!);
	List<MutualFollowerModel> get blockedUsers =>
			List.unmodifiable(_lists[SocialListType.blocked]!);

	bool isListLoading(SocialListType type) => _isLoadingList[type] ?? false;
	String? listError(SocialListType type) => _listErrors[type];
	int listTotal(SocialListType type) => _listTotals[type] ?? 0;

	void setCurrentUser(String userId) {
		final normalized = userId.trim().isEmpty ? 'me' : userId.trim();
		if (_currentUserId == normalized) return;
		_currentUserId = normalized;
		_service.setCurrentUser(_currentUserId);
		notifyListeners();
	}

	Future<void> loadPublicProfile(String userId) async {
		_isLoadingProfile = true;
		_profileError = null;
		notifyListeners();

		try {
			_publicProfile = await _service.getPublicProfile(userId);
			await loadRelationshipStatus(userId, notify: false);
		} catch (e) {
			_profileError = e.toString();
		} finally {
			_isLoadingProfile = false;
			notifyListeners();
		}
	}

	Future<void> loadRelationshipStatus(
		String userId, {
		bool notify = true,
	}) async {
		try {
			_relationshipStatus = await _service.getRelationshipStatus(userId);
		} catch (e) {
			_profileError = e.toString();
		} finally {
			if (notify) {
				notifyListeners();
			}
		}
	}

	Future<void> refreshRelationshipStatus(String userId) async {
		await loadRelationshipStatus(userId);
	}

	Future<void> loadList(
		SocialListType type, {
		required String userId,
		int page = 1,
		int limit = 20,
	}) async {
		_isLoadingList[type] = true;
		_listErrors[type] = null;
		notifyListeners();

		try {
			final response = await _fetchList(type, userId: userId, page: page, limit: limit);
			_lists[type] = response.users;
			_listTotals[type] = response.total;
		} catch (e) {
			_listErrors[type] = e.toString();
		} finally {
			_isLoadingList[type] = false;
			notifyListeners();
		}
	}

	Future<void> loadSuggestedUsers({
		int page = 1,
		int limit = 20,
	}) {
		return loadList(
			SocialListType.suggested,
			userId: _currentUserId,
			page: page,
			limit: limit,
		);
	}

	Future<void> loadFollowers(
		String userId, {
		int page = 1,
		int limit = 20,
	}) {
		return loadList(
			SocialListType.followers,
			userId: userId,
			page: page,
			limit: limit,
		);
	}

	Future<void> loadFollowing(
		String userId, {
		int page = 1,
		int limit = 20,
	}) {
		return loadList(
			SocialListType.following,
			userId: userId,
			page: page,
			limit: limit,
		);
	}

	Future<void> loadMutualFollowers(
		String userId, {
		int page = 1,
		int limit = 20,
	}) {
		return loadList(
			SocialListType.mutualFollowers,
			userId: userId,
			page: page,
			limit: limit,
		);
	}

	Future<void> loadBlockedUsers({
		int page = 1,
		int limit = 20,
	}) {
		return loadList(
			SocialListType.blocked,
			userId: _currentUserId,
			page: page,
			limit: limit,
		);
	}

	Future<void> followUser(String userId) async {
		await _mutateRelationship(userId, () => _service.followUser(userId),
				increaseFollowers: true);
		await _syncAfterFollowMutation();
	}

	Future<void> unfollowUser(String userId) async {
		await _mutateRelationship(userId, () => _service.unfollowUser(userId),
				increaseFollowers: false);
		await _syncAfterFollowMutation();
	}

	Future<void> blockUser(String userId, {String? reason}) async {
		await _mutateRelationship(
			userId,
			() => _service.blockUser(userId, reason: reason),
			removeFromSuggested: true,
			removeFromFollowersAndFollowing: true,
		);

		await _refreshAfterModerationChange(userId);
	}

	Future<void> unblockUser(String userId) async {
		await _mutateRelationship(
			userId,
			() => _service.unblockUser(userId),
			removeFromBlocked: true,
		);

		await _refreshAfterModerationChange(userId);
	}

	Future<void> toggleFollowState(String userId) async {
		final status = _relationshipStatus;
		if (status == null) {
			await followUser(userId);
			return;
		}

		if (status.isFollowing) {
			await unfollowUser(userId);
		} else {
			await followUser(userId);
		}
	}

	void clearTransientErrors() {
		_profileError = null;
		for (final key in _listErrors.keys) {
			_listErrors[key] = null;
		}
		notifyListeners();
	}

	Future<void> _mutateRelationship(
		String userId,
		Future<RelationshipStatusModel> Function() mutation, {
		bool? increaseFollowers,
		bool removeFromSuggested = false,
		bool removeFromBlocked = false,
		bool removeFromFollowersAndFollowing = false,
	}) async {
		_isMutatingRelationship = true;
		_profileError = null;
		notifyListeners();

		try {
			final updated = await mutation();
			_relationshipStatus = updated;

			_updateUserInAllLists(userId, updated);

			if (increaseFollowers != null && _publicProfile != null) {
				final delta = increaseFollowers ? 1 : -1;
				final nextFollowers = (_publicProfile!.followersCount + delta).clamp(0, 1 << 31);
				_publicProfile = _publicProfile!.copyWith(followersCount: nextFollowers);
			}

			if (removeFromSuggested) {
				_lists[SocialListType.suggested] =
						_lists[SocialListType.suggested]!.where((u) => u.id != userId).toList();
			}
			if (removeFromBlocked) {
				_lists[SocialListType.blocked] =
						_lists[SocialListType.blocked]!.where((u) => u.id != userId).toList();
			}
			if (removeFromFollowersAndFollowing) {
				_lists[SocialListType.followers] =
						_lists[SocialListType.followers]!.where((u) => u.id != userId).toList();
				_lists[SocialListType.following] =
						_lists[SocialListType.following]!.where((u) => u.id != userId).toList();
			}
		} catch (e) {
			_profileError = e.toString();
		} finally {
			_isMutatingRelationship = false;
			notifyListeners();
		}
	}

	void _updateUserInAllLists(String userId, RelationshipStatusModel relation) {
		for (final type in _lists.keys) {
			_lists[type] = _lists[type]!.map((user) {
				if (user.id != userId) return user;
				return user.copyWith(
					isFollowing: relation.isFollowing,
					isFollowedBy: relation.isFollowedBy,
				);
			}).toList();
		}

		if (relation.isBlockedByMe) {
			final blockedList = _lists[SocialListType.blocked]!;
			final existing = blockedList.any((u) => u.id == userId);
			if (!existing) {
				final sourceUser = _lists.values
						.expand((entries) => entries)
						.firstWhere(
							(entry) => entry.id == userId,
							orElse: () => MutualFollowerModel(
								id: userId,
								username: userId,
								displayName: userId,
								avatarUrl: '',
								subtitle: 'Blocked',
								isFollowing: false,
								isFollowedBy: false,
							),
						);
				_lists[SocialListType.blocked] = [
					...blockedList,
					sourceUser.copyWith(
						subtitle: 'Blocked',
						isFollowing: false,
						isFollowedBy: false,
					),
				];
			}
		}
	}

	Future<SocialUserListResponse> _fetchList(
		SocialListType type, {
		required String userId,
		required int page,
		required int limit,
	}) {
		switch (type) {
			case SocialListType.followers:
				return _service.getFollowers(userId, page: page, limit: limit);
			case SocialListType.following:
				return _service.getFollowing(userId, page: page, limit: limit);
			case SocialListType.mutualFollowers:
				return _service.getMutualFollowers(userId, page: page, limit: limit);
			case SocialListType.suggested:
				return _service.getSuggestedUsers(page: page, limit: limit);
			case SocialListType.blocked:
				return _service.getBlockedUsers(page: page, limit: limit);
		}
	}

	Future<void> _refreshAfterModerationChange(String userId) async {
		await loadBlockedUsers();
		await loadSuggestedUsers();

		if (_publicProfile?.id == userId) {
			await loadRelationshipStatus(userId);
		}
	}

	Future<void> _syncAfterFollowMutation() async {
		await loadFollowing(_currentUserId);
		await loadSuggestedUsers();
	}
}
