import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Fixes launchUrl errors
import '../core/services/api_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final ApiService _apiService;

  // Data from backend
  int? adIntervalSeconds;
  String? adVideoUrl;
  bool _isLoading = false;
  String _currentPlan = 'Free';
  bool _isPremium = false;

  // Quotas (Mapped to your usage API)
  int currentTrackCount = 0;
  int currentAlbumCount = 0;
  int? maxTrackLimit; 

  // UI state
  bool showAdOverlay = false;
  Timer? _adTimer;

  SubscriptionProvider(this._apiService);

  bool get isLoading => _isLoading;
  bool get isPremium => _isPremium;
  String get currentPlan => _currentPlan;
  SubscriptionProvider get sub => this; // Fixes 'sub' undefined
  int get usedTracks => currentTrackCount;
  dynamic get trackLimit => maxTrackLimit ?? '∞'; 

  Future<void> fetchSubscriptionStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final subData = await _apiService.get('/subscriptions/me');
      final usageData = await _apiService.get('/users/me/usage');

      if (subData != null && usageData != null) {
        _currentPlan = subData['effective_plan'] ?? 'Free';
        _isPremium = _currentPlan == 'Artist Pro';
        
        final features = subData['features'] ?? {};
        adIntervalSeconds = features['ad_interval_seconds'];
        adVideoUrl = features['ad_video_url'];

        final usage = usageData['usage'] ?? {};
        currentTrackCount = usage['uploaded_tracks']?['used'] ?? 0;
        maxTrackLimit = usage['uploaded_tracks']?['limit'];
        currentAlbumCount = usage['albums']?['used'] ?? 0;

        if (!_isPremium && adIntervalSeconds != null) {
          _startAdTimer();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

 
  Future<void> upgradeAccount() async {
    try {
      final response = await _apiService.post('/subscriptions/checkout', {'plan': 'Artist Pro'});
      if (response != null && response['checkout_url'] != null) {
        await launchUrl(Uri.parse(response['checkout_url']), mode: LaunchMode.externalApplication);
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> downgradeAccount() async {
    await _apiService.post('/subscriptions/cancel', {});
    await fetchSubscriptionStatus();
  }


  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer(Duration(seconds: adIntervalSeconds ?? 240), () {
      showAdOverlay = true;
      notifyListeners();
    });
  }

  void closeAd() {
    showAdOverlay = false;
    _startAdTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }
}