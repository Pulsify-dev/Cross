class Playlist {
  final String id;
  String name;
  List<String> tracks;
  bool isPublic;
  String secretToken;

  Playlist({
    required this.id,
    required this.name,
    this.tracks = const [],
    this.isPublic = true,
    this.secretToken = '',
  });
}