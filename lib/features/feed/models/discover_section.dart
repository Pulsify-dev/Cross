import 'package:cross/features/feed/models/track.dart';

class DiscoverSection {
  final String id;
  final String title;
  final String type;
  final List<Track> items;

  DiscoverSection({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
  });

  factory DiscoverSection.fromJson(Map<String, dynamic> json) {
    return DiscoverSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'track_list',
      items: (json['items'] as List?)
              ?.map((item) => Track.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
