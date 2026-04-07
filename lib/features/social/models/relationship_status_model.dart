enum SocialFollowAction {
	follow,
	followBack,
	following,
	none,
}

class RelationshipStatusModel {
	const RelationshipStatusModel({
		required this.isFollowing,
		required this.isFollowedBy,
		required this.isMutual,
		required this.isBlockedByMe,
		required this.isBlockedByThem,
	});

	final bool isFollowing;
	final bool isFollowedBy;
	final bool isMutual;
	final bool isBlockedByMe;
	final bool isBlockedByThem;

	bool get isUnavailable => isBlockedByMe || isBlockedByThem;

	SocialFollowAction get followAction {
		if (isUnavailable) return SocialFollowAction.none;
		if (isFollowing) return SocialFollowAction.following;
		if (isFollowedBy) return SocialFollowAction.followBack;
		return SocialFollowAction.follow;
	}

	String get followLabel {
		switch (followAction) {
			case SocialFollowAction.following:
				return 'Following';
			case SocialFollowAction.followBack:
				return 'Follow back';
			case SocialFollowAction.follow:
				return 'Follow';
			case SocialFollowAction.none:
				return 'Unavailable';
		}
	}

	factory RelationshipStatusModel.fromJson(Map<String, dynamic> json) {
		return RelationshipStatusModel(
			isFollowing: json['isFollowing'] == true || json['is_following'] == true,
			isFollowedBy: json['isFollowedBy'] == true || json['is_followed_by'] == true,
			isMutual: json['isMutual'] == true || json['is_mutual'] == true,
			isBlockedByMe: json['isBlockedByMe'] == true || json['is_blocked_by_me'] == true,
			isBlockedByThem: json['isBlockedByThem'] == true || json['is_blocked_by_them'] == true,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'isFollowing': isFollowing,
			'isFollowedBy': isFollowedBy,
			'isMutual': isMutual,
			'isBlockedByMe': isBlockedByMe,
			'isBlockedByThem': isBlockedByThem,
		};
	}

	RelationshipStatusModel copyWith({
		bool? isFollowing,
		bool? isFollowedBy,
		bool? isMutual,
		bool? isBlockedByMe,
		bool? isBlockedByThem,
	}) {
		return RelationshipStatusModel(
			isFollowing: isFollowing ?? this.isFollowing,
			isFollowedBy: isFollowedBy ?? this.isFollowedBy,
			isMutual: isMutual ?? this.isMutual,
			isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
			isBlockedByThem: isBlockedByThem ?? this.isBlockedByThem,
		);
	}
}
