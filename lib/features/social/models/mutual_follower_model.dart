class MutualFollowerModel {
	const MutualFollowerModel({
		required this.id,
		required this.username,
		required this.displayName,
		required this.avatarUrl,
		required this.subtitle,
		required this.isFollowing,
		required this.isFollowedBy,
	});

	final String id;
	final String username;
	final String displayName;
	final String avatarUrl;
	final String subtitle;
	final bool isFollowing;
	final bool isFollowedBy;

	factory MutualFollowerModel.fromJson(Map<String, dynamic> json) {
		return MutualFollowerModel(
			id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
			username: json['username']?.toString() ?? '',
			displayName: json['displayName']?.toString() ?? json['display_name']?.toString() ?? '',
			avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString() ?? '',
			subtitle: json['subtitle']?.toString() ?? '',
			isFollowing: json['isFollowing'] == true || json['is_following'] == true,
			isFollowedBy: json['isFollowedBy'] == true || json['is_followed_by'] == true,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'username': username,
			'displayName': displayName,
			'avatarUrl': avatarUrl,
			'subtitle': subtitle,
			'isFollowing': isFollowing,
			'isFollowedBy': isFollowedBy,
		};
	}

	MutualFollowerModel copyWith({
		String? id,
		String? username,
		String? displayName,
		String? avatarUrl,
		String? subtitle,
		bool? isFollowing,
		bool? isFollowedBy,
	}) {
		return MutualFollowerModel(
			id: id ?? this.id,
			username: username ?? this.username,
			displayName: displayName ?? this.displayName,
			avatarUrl: avatarUrl ?? this.avatarUrl,
			subtitle: subtitle ?? this.subtitle,
			isFollowing: isFollowing ?? this.isFollowing,
			isFollowedBy: isFollowedBy ?? this.isFollowedBy,
		);
	}
}
