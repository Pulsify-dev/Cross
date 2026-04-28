import 'package:flutter/material.dart';
import 'package:cross/core/services/api_service.dart';
import '../features/premium/models/subscription_model.dart';

class SubscriptionProvider with ChangeNotifier {
  final ApiService _apiService;
  SubscriptionModel? _sub;
  bool _isLoading = false;

  SubscriptionProvider(this._apiService);

  SubscriptionModel? get sub => _sub;
  bool get isLoading => _isLoading;
  String get currentPlan => _sub?.plan ?? "Free";
  bool get isPremium => currentPlan == "Artist Pro";

  Future<void> refreshStatus() async {
    _setLoading(true);
    try {
      final data = await _apiService.get(
        '/users/me/usage', 
        authRequired: true,
      );
      _sub = SubscriptionModel.fromJson(data);
    } catch (e) {
      debugPrint("Status Refresh Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> upgradeAccount() async {
    _setLoading(true);
    try {
      await _apiService.post(
        '/subscriptions/checkout', 
        {}, 
        body: {'plan': 'Artist Pro'}, 
        authRequired: true,
      );
      await refreshStatus(); 
    } catch (e) {
      debugPrint("Upgrade Error: $e");
      _setLoading(false);
    }
  }

  Future<void> downgradeAccount() async {
    _setLoading(true);
    try {
      await _apiService.post(
        '/subscriptions/cancel', 
        {}, 
        authRequired: true,
      );
      await refreshStatus();
    } catch (e) {
      debugPrint("Downgrade Error: $e");
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}