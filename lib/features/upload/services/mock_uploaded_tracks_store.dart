import 'package:flutter/foundation.dart';
import 'package:cross/features/upload/services/mock_uploaded_track.dart';

class MockUploadedTracksStore {
  static const String _defaultArtworkUrl =
      'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=600&auto=format&fit=crop';

  static final ValueNotifier<List<MockUploadedTrack>> tracksNotifier =
      ValueNotifier<List<MockUploadedTrack>>([
        const MockUploadedTrack(
          id: 'seed-1',
          title: 'Neon Sunset Vibes',
          genre: 'Electronic',
          description: 'Warm synth layers and punchy drums.',
          tags: '#electronic #synth',
          privacy: 'Public',
          imageUrl: _defaultArtworkUrl,
          plays: '2.1M plays',
          status: 'Finished',
        ),
        const MockUploadedTrack(
          id: 'seed-2',
          title: 'Midnight Echoes',
          genre: 'Ambient',
          description: 'Late-night textures and evolving pads.',
          tags: '#ambient #night',
          privacy: 'Public',
          imageUrl: _defaultArtworkUrl,
          plays: '850K plays',
          status: 'Finished',
        ),
        const MockUploadedTrack(
          id: 'seed-3',
          title: 'Pacific Drift',
          genre: 'Lo-fi',
          description: 'Soft grooves and nostalgic tones.',
          tags: '#lofi #chill',
          privacy: 'Private',
          imageUrl: _defaultArtworkUrl,
          plays: '1.4M plays',
          status: 'Finished',
        ),
        const MockUploadedTrack(
          id: 'seed-4',
          title: 'City Lights',
          genre: 'Chill Hop',
          description: 'Urban rhythm with smooth melodies.',
          tags: '#chillhop #beats',
          privacy: 'Public',
          imageUrl: _defaultArtworkUrl,
          plays: '920K plays',
          status: 'Finished',
        ),
      ]);

  static String get defaultArtworkUrl => _defaultArtworkUrl;

  static List<MockUploadedTrack> get tracks => tracksNotifier.value;

  static void addTrack(MockUploadedTrack track) {
    tracksNotifier.value = [track, ...tracksNotifier.value];
  }

  static MockUploadedTrack? getById(String id) {
    for (final track in tracksNotifier.value) {
      if (track.id == id) {
        return track;
      }
    }
    return null;
  }

  static void updateTrack(MockUploadedTrack updatedTrack) {
    tracksNotifier.value = tracksNotifier.value
        .map((track) => track.id == updatedTrack.id ? updatedTrack : track)
        .toList();
  }

  static void removeTrack(String id) {
    tracksNotifier.value =
        tracksNotifier.value.where((track) => track.id != id).toList();
  }
}
