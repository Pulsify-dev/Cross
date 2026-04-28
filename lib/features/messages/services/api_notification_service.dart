import '../../../core/services/api_service.dart';
import '../models/notification_model.dart';

class NotificationPage {
	final List<AppNotification> notifications;
	final int currentPage;
	final int totalPages;

	const NotificationPage({
		required this.notifications,
		required this.currentPage,
		required this.totalPages,
	});

	bool get hasMore => currentPage < totalPages;
}

class ApiNotificationService {
	final ApiService _api;

	ApiNotificationService(this._api);

	Future<NotificationPage> getNotifications({
		int page = 1,
		int limit = 20,
	}) async {
		final response = await _api.get(
			'/notifications?page=$page&limit=$limit',
			authRequired: true,
		);

		final rawData = response['data'];
		final list = rawData is List
			? rawData
			: (rawData is Map ? rawData['notifications'] as List? : null) ??
				  const [];
		final meta = (response['meta'] as Map?) ?? const {};

		final notifications = list
				.whereType<Map>()
				.map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item)))
				.toList();

		final currentPage = int.tryParse(meta['currentPage']?.toString() ?? '') ?? page;
		final totalPages = int.tryParse(meta['totalPages']?.toString() ?? '') ?? currentPage;

		return NotificationPage(
			notifications: notifications,
			currentPage: currentPage,
			totalPages: totalPages,
		);
	}

	Future<int> getUnreadCount() async {
		final response = await _api.get(
			'/notifications/unread-count',
			authRequired: true,
		);

		final data = (response['data'] as Map?) ?? const {};
		return int.tryParse(data['unread_count']?.toString() ?? '') ?? 0;
	}

	Future<void> markAllAsRead() async {
		await _api.put('/notifications/read-all', authRequired: true);
	}

	Future<void> markSingleAsRead(String notificationId) async {
		try {
			await _api.put('/notifications/$notificationId/read', authRequired: true);
		} on ApiException catch (e) {
			if (e.statusCode != 404) rethrow;
			// Backward-compatible fallback if backend route naming differs.
			await _api.put('/notifications/read/$notificationId', authRequired: true);
		}
	}

	Future<void> registerPushToken({
		required String token,
		String platform = 'android',
	}) async {
		try {
			await _api.post(
				'/notifications/push-token',
				 {
					'token': token,
					'platform': platform,
				},
				authRequired: true,
			);
		} on ApiException catch (e) {
			if (e.statusCode != 404) rethrow;
			// Backward-compatible fallback if backend route name differs.
			await _api.post(
				'/notifications/register-push-token',
				{
					'token': token,
					'platform': platform,
				},
				authRequired: true,
			);
		}
	}
}
