import 'package:cross/core/services/api_service.dart';


class AdminService {
  final ApiService _api;
  AdminService(this._api);

  //  ANALYTICS 
  Future<Map<String, dynamic>?> getAnalytics() async {
    final response = await _api.get('/admin/analytics', authRequired: true);
    return response as Map<String, dynamic>?;
  }

  //  USER MANAGEMENT 
  Future<bool> suspendUser(String id) async => 
      await _api.put('/admin/users/$id/suspend', authRequired: true) != null;

  Future<bool> restoreUser(String id) async => 
      await _api.put('/admin/users/$id/restore', authRequired: true) != null;

  Future<bool> updateRole(String id, String role) async => 
      await _api.patch('/admin/users/$id/role', body: {'role': role}, authRequired: true) != null;

  // CONTENT MANAGEMENT
  Future<bool> toggleTrackBlock(String id, bool block) async => 
      await _api.patch('/admin/tracks/$id/${block ? 'block' : 'unblock'}', authRequired: true) != null;

  Future<bool> deleteTrack(String id) async => 
      await _api.delete('/admin/tracks/$id', authRequired: true) != null;

  Future<bool> toggleAlbumBlock(String id, bool block) async => 
      await _api.patch('/admin/albums/$id/${block ? 'block' : 'unblock'}', authRequired: true) != null;

  Future<bool> deleteAlbum(String id) async => 
      await _api.delete('/admin/albums/$id', authRequired: true) != null;

  //  LISTS & PAGINATION
  Future<List<dynamic>> fetchList(String type, {int page = 1}) async {
    final res = await _api.get('/admin/$type?page=$page&limit=20', authRequired: true);
    if (res != null && res['data'] != null) {
      return res['data'] as List<dynamic>;
    }
    return [];
  }
}