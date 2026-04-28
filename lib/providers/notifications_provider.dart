import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/messages/models/notification_model.dart';
import '../features/messages/services/api_notification_service.dart';
import '../features/messages/services/socket_service.dart';

class NotificationsProvider extends ChangeNotifier {
	final ApiNotificationService _notificationsApi;
	final SocketService _socket;

	NotificationsProvider(this._notificationsApi, this._socket);

	final List<AppNotification> _notifications = [];

	String? _currentUserId;
	int _currentPage = 1;
	bool _hasMore = true;
	bool _isLoading = false;
	bool _isLoadingMore = false;
	String? _error;
	int _unreadCount = 0;

	StreamSubscription<Map<String, dynamic>>? _newNotificationSub;

	List<AppNotification> get notifications => List.unmodifiable(_notifications);
	bool get isLoading => _isLoading;
	bool get isLoadingMore => _isLoadingMore;
	bool get hasMore => _hasMore;
	String? get error => _error;
	int get unreadCount => _unreadCount;

	List<AppNotification> filtered(String filter) {
		switch (filter) {
			case 'Likes':
				return _notifications
						.where((n) => n.actionType == NotificationActionType.like)
						.toList(growable: false);
			case 'Comments':
				return _notifications
						.where((n) => n.actionType == NotificationActionType.comment)
						.toList(growable: false);
			case 'Reposts':
				return _notifications
						.where((n) => n.actionType == NotificationActionType.repost)
						.toList(growable: false);
			case 'Followers':
				return _notifications
						.where((n) => n.actionType == NotificationActionType.follow)
						.toList(growable: false);
			default:
				return List.unmodifiable(_notifications);
		}
	}

	void setCurrentUser(String? userId) {
		if (_currentUserId == userId) return;
		_currentUserId = userId;
		if (userId == null || userId.isEmpty) {
			_clearState();
			return;
		}
		_initForAuthenticatedUser();
	}

	Future<void> _initForAuthenticatedUser() async {
		await _socket.connect();
		_newNotificationSub?.cancel();
		_newNotificationSub = _socket.onNotificationNew.listen(_onNewNotification);
		_socket.joinNotifications();
		await refresh();
	}

	Future<void> refresh() async {
		if (_currentUserId == null || _currentUserId!.isEmpty) return;

		_isLoading = true;
		_error = null;
		notifyListeners();

		try {
			final page = await _notificationsApi.getNotifications(page: 1, limit: 20);
			_notifications
				..clear()
				..addAll(page.notifications);
			_currentPage = page.currentPage;
			_hasMore = page.hasMore;
			_unreadCount = await _notificationsApi.getUnreadCount();
		} catch (e) {
			_error = e.toString();
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	Future<void> loadMore() async {
		if (_isLoadingMore || !_hasMore || _currentUserId == null) return;
		_isLoadingMore = true;
		notifyListeners();

		try {
			final nextPage = _currentPage + 1;
			final page = await _notificationsApi.getNotifications(
				page: nextPage,
				limit: 20,
			);
			_currentPage = page.currentPage;
			_hasMore = page.hasMore;
			_notifications.addAll(
				page.notifications.where(
					(incoming) => !_notifications.any((n) => n.id == incoming.id),
				),
			);
		} catch (e) {
			_error = e.toString();
		} finally {
			_isLoadingMore = false;
			notifyListeners();
		}
	}

	Future<void> markAllAsRead() async {
		if (_unreadCount == 0) return;
		try {
			await _notificationsApi.markAllAsRead();
			for (var i = 0; i < _notifications.length; i++) {
				if (!_notifications[i].isRead) {
					_notifications[i] = _notifications[i].copyWith(isRead: true);
				}
			}
			_unreadCount = 0;
			notifyListeners();
		} catch (e) {
			_error = e.toString();
			notifyListeners();
		}
	}

	Future<void> markAsRead(String notificationId) async {
		final index = _notifications.indexWhere((n) => n.id == notificationId);
		if (index == -1 || _notifications[index].isRead) return;

		try {
			await _notificationsApi.markSingleAsRead(notificationId);
			_notifications[index] = _notifications[index].copyWith(isRead: true);
			if (_unreadCount > 0) _unreadCount--;
			notifyListeners();
		} catch (e) {
			_error = e.toString();
			notifyListeners();
		}
	}

	void _onNewNotification(Map<String, dynamic> payload) {
		final incoming = AppNotification.fromJson(payload);
		if (incoming.id.isEmpty) return;

		final existingIndex = _notifications.indexWhere((n) => n.id == incoming.id);
		final wasUnread =
				existingIndex != -1 ? !_notifications[existingIndex].isRead : false;
		if (existingIndex != -1) {
			_notifications[existingIndex] = incoming;
		} else {
			_notifications.insert(0, incoming);
		}

		if (!incoming.isRead && !wasUnread) {
			_unreadCount++;
		}

		notifyListeners();
	}

	void _clearState() {
		_newNotificationSub?.cancel();
		_newNotificationSub = null;
		_socket.leaveNotifications();

		_notifications.clear();
		_currentPage = 1;
		_hasMore = true;
		_isLoading = false;
		_isLoadingMore = false;
		_error = null;
		_unreadCount = 0;
		notifyListeners();
	}

	@override
	void dispose() {
		_newNotificationSub?.cancel();
		super.dispose();
	}
}
