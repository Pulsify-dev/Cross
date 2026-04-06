import 'package:flutter/material.dart';
import 'package:cross/features/profile/models/profile_data.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileData _profile = ProfileData(
    avatarPath: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEMPbFfQ4nJKoMGtW4vLU1EkYvFsZ5Y7czHX8HZuJarT5Ey6cf3HymK4qt_nQL6ynBvlJD0TBa8v7GvtU_owxQhBATdawLxagrbBt4w5WEzbhbP0KV_cnvFMgQw8av70WDNr9xwDryKEBMBoPvMiz_bWRulpaXVvdNERyFs0W0vcNEhrfcp6Mq0qRCVLLL1Ra_PAPQC-DGRChlfhKq0w4Tm23xvcIg7DQeRfs_ATPCUdH9jE2PbIg83ATUYMrgnoBbHXjKqjhyfs',
    avatarBytes: null,
    username: 'Alex Rivers',
    bio: 'Music producer & sound designer based in LA. Bringing lo-fi beats to your late night sessions. 🎵',
    email: 'alex@example.com',
  );

  ProfileData get profile => _profile;

  void updateProfile(ProfileData newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}