import '../models/track.dart';
import '../models/user.dart';
import '../models/comment.dart';
import 'track_service.dart';

class MockTrackService implements TrackService {
  final List<Track> _mockTracks = [
    Track(
      id: '1',
      title: 'Neon Nights',
      artistName: 'SynthWave Pro',
      artworkUrl: 'https://picsum.photos/seed/track1/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      duration: const Duration(minutes: 3, seconds: 45),
      playCount: 15400,
      likeCount: 1200,
      commentCount: 45,
      repostCount: 120,
      genres: ['Electronic', 'Synthwave'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      uploader: User(
        id: 'u1',
        username: 'synth_pro',
        displayName: 'SynthWave Pro',
      ),
    ),
    Track(
      id: '2',
      title: 'Midnight Rain',
      artistName: 'LoFi Girl',
      artworkUrl: 'https://picsum.photos/seed/track2/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      duration: const Duration(minutes: 2, seconds: 30),
      playCount: 89000,
      likeCount: 5600,
      commentCount: 120,
      repostCount: 800,
      genres: ['Lo-Fi', 'Chill'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      uploader: User(id: 'u2', username: 'lofi_girl', displayName: 'LoFi Girl'),
    ),
    Track(
      id: '3',
      title: 'Mountain Peak',
      artistName: 'Acoustic Soul',
      artworkUrl: 'https://picsum.photos/seed/track3/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      duration: const Duration(minutes: 4, seconds: 15),
      playCount: 12000,
      likeCount: 800,
      commentCount: 30,
      repostCount: 50,
      genres: ['Acoustic', 'Indie'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      uploader: User(
        id: 'u3',
        username: 'acoustic_soul',
        displayName: 'Acoustic Soul',
      ),
    ),
    Track(
      id: '4',
      title: 'Digital Horizon',
      artistName: 'Cyber Artist',
      artworkUrl: 'https://picsum.photos/seed/track4/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      duration: const Duration(minutes: 5, seconds: 0),
      playCount: 4500,
      likeCount: 300,
      commentCount: 12,
      repostCount: 20,
      genres: ['Electronic', 'Techno'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      uploader: User(
        id: 'u4',
        username: 'cyber_art',
        displayName: 'Cyber Artist',
      ),
    ),
    Track(
      id: '5',
      title: 'Sunset Boulevard',
      artistName: 'Retro Wave',
      artworkUrl: 'https://picsum.photos/seed/track5/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      duration: const Duration(minutes: 4, seconds: 12),
      playCount: 25000,
      likeCount: 1800,
      commentCount: 88,
      repostCount: 200,
      genres: ['Synthwave', 'Retrowave'],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      uploader: User(
        id: 'u5',
        username: 'retro_wave',
        displayName: 'Retro Wave',
      ),
    ),
    Track(
      id: '6',
      title: 'Ocean Waves',
      artistName: 'Nature Sounds',
      artworkUrl: 'https://picsum.photos/seed/track6/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      duration: const Duration(minutes: 10, seconds: 0),
      playCount: 120000,
      likeCount: 9500,
      commentCount: 450,
      repostCount: 1200,
      genres: ['Ambient', 'Relaxation'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      uploader: User(
        id: 'u6',
        username: 'nature_zen',
        displayName: 'Nature Zen',
      ),
    ),
    Track(
      id: '7',
      title: 'Urban Jungle',
      artistName: 'Street Beat',
      artworkUrl: 'https://picsum.photos/seed/track7/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      duration: const Duration(minutes: 3, seconds: 15),
      playCount: 6700,
      likeCount: 420,
      commentCount: 25,
      repostCount: 60,
      genres: ['Hip-Hop', 'Urban'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      uploader: User(
        id: 'u7',
        username: 'street_beat',
        displayName: 'Street Beat',
      ),
    ),
    Track(
      id: '8',
      title: 'Galactic Voyage',
      artistName: 'Star Child',
      artworkUrl: 'https://picsum.photos/seed/track8/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      duration: const Duration(minutes: 6, seconds: 45),
      playCount: 15000,
      likeCount: 110000000,
      commentCount: 65000,
      repostCount: 250000,
      genres: ['Space', 'Electronic'],
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      uploader: User(
        id: 'u8',
        username: 'star_child',
        displayName: 'Star Child',
      ),
    ),
    Track(
      id: '9',
      title: 'Wildfire',
      artistName: 'Fire Starter',
      artworkUrl: 'https://picsum.photos/seed/track9/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
      duration: const Duration(minutes: 3, seconds: 55),
      playCount: 8900,
      likeCount: 560,
      commentCount: 38,
      repostCount: 45,
      genres: ['Rock', 'Alternative'],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      uploader: User(
        id: 'u9',
        username: 'fire_starter',
        displayName: 'Fire Starter',
      ),
    ),
    Track(
      id: '10',
      title: 'Deep Blue',
      artistName: 'Oceania',
      artworkUrl: 'https://picsum.photos/seed/track10/400/400',
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
      duration: const Duration(minutes: 5, seconds: 20),
      playCount: 34000,
      likeCount: 2200,
      commentCount: 115,
      repostCount: 180,
      genres: ['Chill', 'Ambient'],
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      uploader: User(
        id: 'u10',
        username: 'oceania_music',
        displayName: 'Oceania',
      ),
    ),
  ];

  final Set<String> _likedTrackIds = {};
  final Set<String> _likedCommentIds = {};
  final Map<String, List<Comment>> _trackComments = {};
  final Map<String, List<User>> _trackLikesMap = {};
  final List<Track> _historyTracks = [];
  User? _currentUser;

  MockTrackService() {
    // Initialize history with some example tracks
    if (_mockTracks.length >= 2) {
      _historyTracks.add(_mockTracks[0]);
      _historyTracks.add(_mockTracks[1]);
    }

    // Initialize with some default comments
    for (var track in _mockTracks) {
      _trackComments[track.id] = [
        Comment(
          id: 'c1_${track.id}',
          trackId: track.id,
          userId: 'u1',
          username: 'synth_pro',
          text: 'Great track! Love the energy.',
          timestampInTrack: const Duration(seconds: 45),
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Comment(
          id: 'c2_${track.id}',
          trackId: track.id,
          userId: 'u2',
          username: 'lofi_girl',
          text: 'This is my favorite!',
          timestampInTrack: const Duration(seconds: 120),
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];
      // Update initial count to match mock data
      track.commentCount = _trackComments[track.id]!.length;

      // Initialize with default likes
      _trackLikesMap[track.id] = [
        User(id: 'u1', username: 'synth_pro', displayName: 'SynthWave Pro'),
        User(id: 'u2', username: 'lofi_girl', displayName: 'LoFi Girl'),
      ];
    }
  }

  @override
  Future<List<Track>> getTrendingTracks({String? genre}) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Calculate score and sort
    var tracksToProcess = genre != null
        ? _mockTracks
              .where(
                (t) =>
                    t.genres.any((g) => g.toLowerCase() == genre.toLowerCase()),
              )
              .toList()
        : _mockTracks;

    final sortedTracks = List<Track>.from(tracksToProcess);
    sortedTracks.sort((a, b) {
      double scoreA =
          (a.playCount * 0.4) +
          (a.likeCount * 0.3) +
          (a.commentCount * 0.1) +
          (a.repostCount * 0.2);
      double scoreB =
          (b.playCount * 0.4) +
          (b.likeCount * 0.3) +
          (b.commentCount * 0.1) +
          (b.repostCount * 0.2);
      return scoreB.compareTo(scoreA); // Descending
    });

    // Limit to 12
    final trending = sortedTracks.take(12).map((t) {
      t.isLiked = _likedTrackIds.contains(t.id);
      return t;
    }).toList();

    return trending;
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (query.isEmpty) return [];
    return _mockTracks
        .where(
          (t) =>
              t.title.toLowerCase().contains(query.toLowerCase()) ||
              t.artistName.toLowerCase().contains(query.toLowerCase()),
        )
        .map((t) {
          t.isLiked = _likedTrackIds.contains(t.id);
          return t;
        })
        .toList();
  }

  @override
  Future<Track?> getTrackById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final track = _mockTracks.firstWhere((t) => t.id == id);
      track.isLiked = _likedTrackIds.contains(track.id);

      // Add to history
      _historyTracks.removeWhere((t) => t.id == track.id);
      _historyTracks.insert(0, track);

      return track;
    } catch (_) {
      return null;
    }
  }

  @override
  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  @override
  Future<void> likeTrack(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _likedTrackIds.add(trackId);

    // Add current user to likes map
    if (_currentUser != null) {
      if (!_trackLikesMap[trackId]!.any((u) => u.id == _currentUser!.id)) {
        _trackLikesMap[trackId]!.add(_currentUser!);
      }
    }
  }

  @override
  Future<void> unlikeTrack(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _likedTrackIds.remove(trackId);

    // Remove current user from likes map
    if (_currentUser != null) {
      _trackLikesMap[trackId]?.removeWhere((u) => u.id == _currentUser!.id);
    }
  }

  @override
  Future<List<Track>> getLikedTracks() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockTracks.where((t) => _likedTrackIds.contains(t.id)).map((t) {
      t.isLiked = true;
      return t;
    }).toList();
  }

  @override
  Future<List<Track>> getActivityFeed() async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Simulate user activity feed with some random tracks
    return _mockTracks.reversed.toList();
  }

  @override
  Future<List<Track>> getListeningHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _historyTracks;
  }

  @override
  Future<List<Comment>> getComments(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final comments = _trackComments[trackId] ?? [];
    return comments
        .map(
          (c) => Comment(
            id: c.id,
            trackId: c.trackId,
            userId: c.userId,
            username: c.username,
            userProfileImageUrl: c.userProfileImageUrl,
            text: c.text,
            timestampInTrack: c.timestampInTrack,
            createdAt: c.createdAt,
            likeCount: c.likeCount + (_likedCommentIds.contains(c.id) ? 1 : 0),
            isLiked: _likedCommentIds.contains(c.id),
            parentCommentId: c.parentCommentId,
          ),
        )
        .toList();
  }

  @override
  Future<void> addComment(
    String trackId,
    String userId,
    String text,
    Duration timestampInTrack, {
    String? parentCommentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newComment = Comment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      trackId: trackId,
      userId: userId,
      username: 'You', // In a real app, this would come from AuthProvider
      text: text,
      timestampInTrack: timestampInTrack,
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
    );

    if (_trackComments.containsKey(trackId)) {
      _trackComments[trackId]!.add(newComment);
    } else {
      _trackComments[trackId] = [newComment];
    }

    // Update the track's comment count in memory
    try {
      final track = _mockTracks.firstWhere((t) => t.id == trackId);
      track.commentCount = _trackComments[trackId]!.length;
    } catch (_) {}
  }

  @override
  Future<void> recordPlay(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final track = _mockTracks.firstWhere((t) => t.id == trackId);
      _historyTracks.removeWhere((t) => t.id == track.id);
      _historyTracks.insert(0, track);
    } catch (_) {}
  }

  @override
  Future<List<User>> getTrackLikes(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _trackLikesMap[trackId] ?? [];
  }

  @override
  Future<List<User>> getSuggestedArtists() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Pick unique uploaders from mock tracks
    final artists = <String, User>{};
    for (var track in _mockTracks) {
      if (track.uploader != null && !artists.containsKey(track.uploader!.id)) {
        artists[track.uploader!.id] = track.uploader!;
      }
    }
    return artists.values.toList().take(5).toList();
  }

  @override
  Future<void> likeComment(String commentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _likedCommentIds.add(commentId);
  }

  @override
  Future<List<Track>> getUserTracks(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTracks.where((t) => t.uploader?.id == userId).toList();
  }

  @override
  Future<void> unlikeComment(String commentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _likedCommentIds.remove(commentId);
  }
}
