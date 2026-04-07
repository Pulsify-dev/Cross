import 'package:cross/features/social/models/mutual_follower_model.dart';

class SocialUserListResponse {
	const SocialUserListResponse({
		required this.users,
		required this.page,
		required this.limit,
		required this.total,
		required this.hasMore,
	});

	final List<MutualFollowerModel> users;
	final int page;
	final int limit;
	final int total;
	final bool hasMore;

	factory SocialUserListResponse.fromJson(Map<String, dynamic> json) {
		final usersRaw = _extractUsersRaw(json);
		final page = _toInt(json['page']) ?? 1;
		final limit = _toInt(json['limit']) ?? usersRaw.length;
		final total = _toInt(json['total']) ?? usersRaw.length;

		return SocialUserListResponse(
			users: usersRaw
					.whereType<Map<String, dynamic>>()
					.map(MutualFollowerModel.fromJson)
					.toList(),
			page: page,
			limit: limit,
			total: total,
			hasMore: json['hasMore'] == true || (page * limit) < total,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'users': users.map((user) => user.toJson()).toList(),
			'page': page,
			'limit': limit,
			'total': total,
			'hasMore': hasMore,
		};
	}

	SocialUserListResponse copyWith({
		List<MutualFollowerModel>? users,
		int? page,
		int? limit,
		int? total,
		bool? hasMore,
	}) {
		return SocialUserListResponse(
			users: users ?? this.users,
			page: page ?? this.page,
			limit: limit ?? this.limit,
			total: total ?? this.total,
			hasMore: hasMore ?? this.hasMore,
		);
	}

	static int? _toInt(dynamic value) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value == null) return null;
		return int.tryParse(value.toString());
	}

	static List<dynamic> _extractUsersRaw(Map<String, dynamic> json) {
		const possibleKeys = [
			'users',
			'suggestedUsers',
			'followers',
			'following',
			'mutualFollowers',
			'blockedUsers',
			'blockers',
		];

		for (final key in possibleKeys) {
			final value = json[key];
			if (value is List) {
				return value;
			}
		}

		return const [];
	}
}
