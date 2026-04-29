class Playlist {
  final String id;
  final String title;
  final String? description;
  final bool isPublic;
  final bool isPremium; // Fixes undefined getter 'isPremium'
  final List<String> trackIds;

  Playlist({
    required this.id,
    required this.title,
    this.description,
    this.isPublic = true,
    this.isPremium = false,
    this.trackIds = const [],
  });

  // Fixes 'copyWith isn't defined'
  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPublic,
    bool? isPremium,
    List<String>? trackIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      isPremium: isPremium ?? this.isPremium,
      trackIds: trackIds ?? this.trackIds,
    );
  }
factory Playlist.fromJson(Map<String, dynamic> json) {
  return Playlist(
    id: json['_id'] ?? json['id'] ?? '',
    title: json['name'] ?? json['title'] ?? 'Untitled',
    // Check for 'desc' (common in SoundCloud-style APIs)
    description: json['description'] ?? json['desc'] ?? json['details'] ?? 'No description provided', 
    isPublic: json['isPublic'] ?? true,
    isPremium: json['isPremium'] ?? false,
    trackIds: List<String>.from(json['tracks'] ?? []),
  );
}
}