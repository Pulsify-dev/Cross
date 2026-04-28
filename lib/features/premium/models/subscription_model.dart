class SubscriptionModel {
  final String plan;
  final int usedTracks;
  final int? trackLimit; // Null = Unlimited

  SubscriptionModel({
    required this.plan,
    required this.usedTracks,
    this.trackLimit,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      plan: json['plan'] ?? 'Free',
      usedTracks: json['usage.uploaded_tracks']['used'] ?? 0,
      trackLimit: json['usage.uploaded_tracks']['limit'],
    );
  }

  bool get isLimitReached => trackLimit != null && usedTracks >= trackLimit!;
}