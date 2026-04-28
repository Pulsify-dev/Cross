class PublicProfileModel {
	const PublicProfileModel({
		required this.id,
		required this.username,
		required this.displayName,
		required this.bio,
		required this.avatarUrl,
		required this.coverUrl,
		required this.isVerified,
		required this.followersCount,
		required this.followingCount,
		required this.mutualFollowersCount,
		required this.trackCount,
		required this.playlistCount,
		required this.favoriteGenres,
		required this.uploadedTracks,
		required this.playlists,
		required this.socialLinks,
	});

	final String id;
	final String username;
	final String displayName;
	final String bio;
	final String avatarUrl;
	final String coverUrl;
	final bool isVerified;
	final int followersCount;
	final int followingCount;
	final int mutualFollowersCount;
	final int trackCount;
	final int playlistCount;
	final List<String> favoriteGenres;
	final List<String> uploadedTracks;
	final List<String> playlists;
	final Map<String, String> socialLinks;

	factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
		return PublicProfileModel(
			id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
			username: json['username']?.toString() ?? '',
			displayName: json['displayName']?.toString() ?? json['display_name']?.toString() ?? '',
			bio: json['bio']?.toString() ?? '',
			avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString() ?? '',
			coverUrl: json['coverUrl']?.toString() ?? json['cover_url']?.toString() ?? '',
			isVerified: json['isVerified'] == true || json['is_verified'] == true,
			followersCount: _toInt(json['followersCount'] ?? json['followers_count']) ?? 0,
			followingCount: _toInt(json['followingCount'] ?? json['following_count']) ?? 0,
			mutualFollowersCount: _toInt(json['mutualFollowersCount'] ?? json['mutual_followers_count']) ?? 0,
			trackCount: _toInt(json['trackCount'] ?? json['track_count']) ?? 0,
			playlistCount: _toInt(json['playlistCount'] ?? json['playlist_count']) ?? 0,
			favoriteGenres: _toStringList(json['favoriteGenres'] ?? json['favorite_genres']),
			uploadedTracks: _toStringList(json['uploadedTracks'] ?? json['uploaded_tracks']),
			playlists: _toStringList(json['playlists']),
			socialLinks: _toStringMap(json['social_links'] ?? json['socialLinks']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'username': username,
			'displayName': displayName,
			'bio': bio,
			'avatarUrl': avatarUrl,
			'coverUrl': coverUrl,
			'isVerified': isVerified,
			'followersCount': followersCount,
			'followingCount': followingCount,
			'mutualFollowersCount': mutualFollowersCount,
			'trackCount': trackCount,
			'playlistCount': playlistCount,
			'favoriteGenres': favoriteGenres,
			'uploadedTracks': uploadedTracks,
			'playlists': playlists,
			'social_links': socialLinks,
		};
	}

	PublicProfileModel copyWith({
		String? id,
		String? username,
		String? displayName,
		String? bio,
		String? avatarUrl,
		String? coverUrl,
		bool? isVerified,
		int? followersCount,
		int? followingCount,
		int? mutualFollowersCount,
		int? trackCount,
		int? playlistCount,
		List<String>? favoriteGenres,
		List<String>? uploadedTracks,
		List<String>? playlists,
		Map<String, String>? socialLinks,
	}) {
		return PublicProfileModel(
			id: id ?? this.id,
			username: username ?? this.username,
			displayName: displayName ?? this.displayName,
			bio: bio ?? this.bio,
			avatarUrl: avatarUrl ?? this.avatarUrl,
			coverUrl: coverUrl ?? this.coverUrl,
			isVerified: isVerified ?? this.isVerified,
			followersCount: followersCount ?? this.followersCount,
			followingCount: followingCount ?? this.followingCount,
			mutualFollowersCount: mutualFollowersCount ?? this.mutualFollowersCount,
			trackCount: trackCount ?? this.trackCount,
			playlistCount: playlistCount ?? this.playlistCount,
			favoriteGenres: favoriteGenres ?? this.favoriteGenres,
			uploadedTracks: uploadedTracks ?? this.uploadedTracks,
			playlists: playlists ?? this.playlists,
			socialLinks: socialLinks ?? this.socialLinks,
		);
	}

	static int? _toInt(dynamic value) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value == null) return null;
		return int.tryParse(value.toString());
	}

	static List<String> _toStringList(dynamic value) {
		if (value is List) {
			return value.map((item) => item.toString()).toList();
		}
		return const <String>[];
	}

	static Map<String, String> _toStringMap(dynamic value) {
		if (value is Map) {
			return Map.fromEntries(
				value.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
			);
		}
		return const <String, String>{};
	}
}
