import '../models/user.dart';
import 'user_service.dart';

class MockUserService implements UserService {
  User? _currentUser;

  @override
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (email == 'test@example.com' && password == 'password') {
      _currentUser = User(
        id: 'u123',
        username: 'alex_rivers',
        displayName: 'Alex Rivers',
        profileImageUrl: 'https://picsum.photos/seed/user1/200/200',
        followersCount: 12400,
        followingCount: 450,
        tracksCount: 86,
        bio:
            'Music producer & sound designer based in LA. Bringing lo-fi beats to your late night sessions. 🎵',
      );
      return _currentUser;
    } else if (email == 'user@example.com' && password == 'password') {
      _currentUser = User(
        id: 'u456',
        username: 'melody_maker92',
        displayName: 'Melody Maker',
        profileImageUrl: 'https://picsum.photos/seed/user2/200/200',
        followersCount: 10,
        followingCount: 20,
        tracksCount: 0,
        bio:
            'Lover of indie folk and electronic beats. Always searching for the next great vinyl find.',
      );
      return _currentUser;
    }
    return null;
  }

  @override
  Future<User?> register(String username, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    _currentUser = User(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      displayName: username,
      followersCount: 0,
      followingCount: 0,
      tracksCount: 0,
    );
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulate sending email
  }

  @override
  Future<User?> updateProfile(User user) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _currentUser = user;
    return _currentUser;
  }

  @override
  Future<User?> updateProfileImage(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    // In a mock service, we'll just simulte the update by using a local file-like placeholder
    // In a real app, this would upload the file to a server and get back a URL
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        profileImageUrl:
            'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200',
      );
    }
    return _currentUser;
  }

  @override
  Future<List<User>> getSuggestedArtists() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      User(
        id: 'u1',
        username: 'synth_pro',
        displayName: 'SynthWave Pro',
        profileImageUrl: 'https://picsum.photos/seed/artist1/200/200',
        followersCount: 1200,
      ),
      User(
        id: 'u2',
        username: 'lofi_girl',
        displayName: 'LoFi Girl',
        profileImageUrl: 'https://picsum.photos/seed/artist2/200/200',
        followersCount: 50000,
      ),
      User(
        id: 'u3',
        username: 'acoustic_soul',
        displayName: 'Acoustic Soul',
        profileImageUrl: 'https://picsum.photos/seed/artist3/200/200',
        followersCount: 800,
      ),
      User(
        id: 'u4',
        username: 'cyber_art',
        displayName: 'Cyber Artist',
        profileImageUrl: 'https://picsum.photos/seed/artist4/200/200',
        followersCount: 2500,
      ),
      User(
        id: 'u5',
        username: 'retro_wave',
        displayName: 'Retro Wave',
        profileImageUrl: 'https://picsum.photos/seed/artist5/200/200',
        followersCount: 3400,
      ),
    ];
  }
}
