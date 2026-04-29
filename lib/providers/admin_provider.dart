import 'package:flutter/material.dart';
import '../features/feed/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service;
  AdminProvider(this._service);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? stats;
  List<dynamic> items = [];
  String currentView = 'users'; // users, tracks,  albums

  // Initialize Dashboard
  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      stats = await _service.getAnalytics();
      items = await _service.fetchList(currentView);
    } catch (e) {
      debugPrint("Admin Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Switch between Users, Tracks, and Albums
  Future<void> setView(String view) async {
    currentView = view;
    await fetchDashboard();
  }

  // Action: Toggle User Status
  Future<void> handleUserStatus(String id, bool isSuspended) async {
    final success = isSuspended ? await _service.restoreUser(id) : await _service.suspendUser(id);
    if (success) await fetchDashboard();
  }

  // Action: Content Control
  Future<void> removeContent(String id, bool isTrack) async {
    final success = isTrack ? await _service.deleteTrack(id) : await _service.deleteAlbum(id);
    if (success) await fetchDashboard();
  }
}