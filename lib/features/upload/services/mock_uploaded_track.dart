import 'dart:typed_data';

class MockUploadedTrack {
  const MockUploadedTrack({
    required this.id,
    required this.title,
    required this.genre,
    required this.description,
    required this.tags,
    required this.privacy,
    required this.imageUrl,
    required this.plays,
    required this.status,
    this.audioFileName,
    this.artworkBytes,
  });

  final String id;
  final String title;
  final String genre;
  final String description;
  final String tags;
  final String privacy;
  final String imageUrl;
  final String plays;
  final String status;
  final String? audioFileName;
  final Uint8List? artworkBytes;

  String get subtitle => '$genre • $status';

  MockUploadedTrack copyWith({
    String? id,
    String? title,
    String? genre,
    String? description,
    String? tags,
    String? privacy,
    String? imageUrl,
    String? plays,
    String? status,
    String? audioFileName,
    Uint8List? artworkBytes,
  }) {
    return MockUploadedTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      privacy: privacy ?? this.privacy,
      imageUrl: imageUrl ?? this.imageUrl,
      plays: plays ?? this.plays,
      status: status ?? this.status,
      audioFileName: audioFileName ?? this.audioFileName,
      artworkBytes: artworkBytes ?? this.artworkBytes,
    );
  }
}
