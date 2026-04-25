enum NotificationActionType {
	like,
	comment,
	repost,
	follow,
	message,
	unknown,
}

class AppNotification {
	final String id;
	final String recipientId;
	final String? actorId;
	final String actorDisplayName;
	final String? actorAvatarUrl;
	final String entityType;
	final String entityId;
	final NotificationActionType actionType;
	final bool isRead;
	final DateTime createdAt;

	const AppNotification({
		required this.id,
		required this.recipientId,
		required this.actorId,
		required this.actorDisplayName,
		required this.actorAvatarUrl,
		required this.entityType,
		required this.entityId,
		required this.actionType,
		required this.isRead,
		required this.createdAt,
	});

	factory AppNotification.fromJson(Map<String, dynamic> json) {
		final rawActor = json['actor_id'];

		String? actorId;
		String actorDisplayName = 'Someone';
		String? actorAvatarUrl;

		if (rawActor is Map<String, dynamic>) {
			actorId = rawActor['_id']?.toString();
			actorDisplayName =
					rawActor['display_name']?.toString() ?? actorDisplayName;
			actorAvatarUrl = rawActor['avatar_url']?.toString();
		} else {
			actorId = rawActor?.toString();
		}

		final createdAtRaw =
				json['created_at']?.toString() ?? json['createdAt']?.toString();

		return AppNotification(
			id: json['_id']?.toString() ?? '',
			recipientId: json['recipient_id']?.toString() ?? '',
			actorId: actorId,
			actorDisplayName: actorDisplayName,
			actorAvatarUrl: actorAvatarUrl,
			entityType: json['entity_type']?.toString() ?? '',
			entityId: json['entity_id']?.toString() ?? '',
			actionType: NotificationActionTypeX.fromApi(
				json['action_type']?.toString(),
			),
			isRead: json['is_read'] == true,
			createdAt: DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now(),
		);
	}

	AppNotification copyWith({
		bool? isRead,
		String? actorDisplayName,
		String? actorAvatarUrl,
	}) {
		return AppNotification(
			id: id,
			recipientId: recipientId,
			actorId: actorId,
			actorDisplayName: actorDisplayName ?? this.actorDisplayName,
			actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
			entityType: entityType,
			entityId: entityId,
			actionType: actionType,
			isRead: isRead ?? this.isRead,
			createdAt: createdAt,
		);
	}
}

extension NotificationActionTypeX on NotificationActionType {
	static NotificationActionType fromApi(String? value) {
		switch ((value ?? '').toUpperCase()) {
			case 'LIKE':
				return NotificationActionType.like;
			case 'COMMENT':
				return NotificationActionType.comment;
			case 'REPOST':
				return NotificationActionType.repost;
			case 'FOLLOW':
				return NotificationActionType.follow;
			case 'MESSAGE':
				return NotificationActionType.message;
			default:
				return NotificationActionType.unknown;
		}
	}

	String get label {
		switch (this) {
			case NotificationActionType.like:
				return 'liked your track';
			case NotificationActionType.comment:
				return 'commented on your track';
			case NotificationActionType.repost:
				return 'reposted your track';
			case NotificationActionType.follow:
				return 'started following you';
			case NotificationActionType.message:
				return 'sent you a message';
			case NotificationActionType.unknown:
				return 'interacted with your content';
		}
	}
}
