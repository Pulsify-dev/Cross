import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/profile/models/profile_data.dart';
import 'package:cross/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _emailController;
  late TextEditingController _favoriteGenresController;
  late TextEditingController _instagramController;
  late TextEditingController _xController;
  late TextEditingController _facebookController;
  late TextEditingController _websiteController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late String _avatarPath;
  Uint8List? _avatarBytes;
  bool _isAvatarUploading = false;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    if (profile != null) {
      _avatarPath = profile.avatarPath ?? '';
      _avatarBytes = profile.avatarBytes;
      _displayNameController = TextEditingController(
        text: profile.displayName?.isNotEmpty == true
            ? profile.displayName
            : profile.username,
      );
      _bioController = TextEditingController(text: profile.bio);
      _locationController = TextEditingController(text: profile.location ?? '');
      _emailController = TextEditingController(text: profile.email);
      _favoriteGenresController = TextEditingController(
        text: profile.favoriteGenres?.join(', ') ?? '',
      );
      _instagramController = TextEditingController(
        text: profile.socialLinks?['instagram'] ?? '',
      );
      _xController = TextEditingController(
        text: profile.socialLinks?['x'] ?? '',
      );
      _facebookController = TextEditingController(
        text: profile.socialLinks?['facebook'] ?? '',
      );
      _websiteController = TextEditingController(
        text: profile.socialLinks?['website'] ?? '',
      );
      _isPrivate = profile.isPrivate ?? false;
      _currentPasswordController = TextEditingController();
      _newPasswordController = TextEditingController();
      _confirmPasswordController = TextEditingController();
    } else {
      _avatarPath = '';
      _avatarBytes = null;
      _displayNameController = TextEditingController();
      _bioController = TextEditingController();
      _locationController = TextEditingController();
      _emailController = TextEditingController();
      _favoriteGenresController = TextEditingController();
      _instagramController = TextEditingController();
      _xController = TextEditingController();
      _facebookController = TextEditingController();
      _websiteController = TextEditingController();
      _currentPasswordController = TextEditingController();
      _newPasswordController = TextEditingController();
      _confirmPasswordController = TextEditingController();
      _isPrivate = false;
    }
  }

  Future<void> _pickImage() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isAvatarUploading = true;
    });

    try {
      await profileProvider.uploadAvatar(bytes);

      if (!mounted) return;

      // Reload profile to get the updated avatar URL from server
      await profileProvider.loadMyProfile();

      if (!mounted) return;

      // Update local state with the new avatar from the reloaded profile
      if (profileProvider.profile != null) {
        setState(() {
          _avatarPath = profileProvider.profile!.avatarPath ?? '';
          _avatarBytes = profileProvider.profile!.avatarBytes;
          _isAvatarUploading = false;
        });
      } else {
        setState(() {
          _isAvatarUploading = false;
        });
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Avatar uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAvatarUploading = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to upload avatar: $e')),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _favoriteGenresController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _facebookController.dispose();
    _websiteController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        centerTitle: true,
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image(
                              image: avatarImage(
                                path: _avatarPath.isNotEmpty
                                    ? _avatarPath
                                    : null,
                                bytes: _avatarBytes,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.surfaceElevated,
                                    child: Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 52,
                                        color: AppColors.iconMuted.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isAvatarUploading ? null : _pickImage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.glow,
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.photo_camera,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isAvatarUploading ? null : _pickImage,
                      child: Text(
                        'Change Profile Picture',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildFormField(
                context,
                label: 'Display Name',
                controller: _displayNameController,
                icon: Icons.person,
              ),
              const SizedBox(height: 20),

              _buildBioField(context),
              const SizedBox(height: 20),

              _buildFormField(
                context,
                label: 'Location',
                controller: _locationController,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 20),

              _buildFormField(
                context,
                label: 'Favorite Genres',
                controller: _favoriteGenresController,
                icon: Icons.music_note,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              Text(
                'Social Links',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                label: 'Instagram',
                controller: _instagramController,
                icon: Icons.camera_alt,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                label: 'X / Twitter',
                controller: _xController,
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                label: 'Facebook',
                controller: _facebookController,
                icon: Icons.facebook,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                label: 'Website',
                controller: _websiteController,
                icon: Icons.link,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              _buildPrivacyToggle(context),
              const SizedBox(height: 20),

              _buildFormField(
                context,
                label: 'Email',
                controller: _emailController,
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),
              const SizedBox(height: 24),

              _buildChangePasswordButton(context),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () async {
                  final profileProvider = Provider.of<ProfileProvider>(
                    context,
                    listen: false,
                  );

                  final messenger = ScaffoldMessenger.of(context);

                  if (profileProvider.profile == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Unable to save profile.')),
                    );
                    return;
                  }

                  final favoriteGenres = _favoriteGenresController.text
                      .split(',')
                      .map((genre) => genre.trim())
                      .where((genre) => genre.isNotEmpty)
                      .toList();

                  final socialLinks = {
                    if (_instagramController.text.trim().isNotEmpty)
                      'instagram': _instagramController.text.trim(),
                    if (_xController.text.trim().isNotEmpty)
                      'x': _xController.text.trim(),
                    if (_facebookController.text.trim().isNotEmpty)
                      'facebook': _facebookController.text.trim(),
                    if (_websiteController.text.trim().isNotEmpty)
                      'website': _websiteController.text.trim(),
                  };

                  try {
                    await profileProvider.updateMyProfile(
                      displayName: _displayNameController.text,
                      bio: _bioController.text,
                      location: _locationController.text.isNotEmpty
                          ? _locationController.text
                          : null,
                      favoriteGenres: favoriteGenres.isNotEmpty
                          ? favoriteGenres
                          : null,
                      socialLinks:
                          socialLinks.isNotEmpty ? socialLinks : null,
                      isPrivate: _isPrivate,
                    );

                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Changes saved!')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to save: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                child: Text(
                  'Discard Changes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield,
                          size: 16,
                          color: AppColors.iconMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last updated 2 days ago',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text(
                              'Are you sure you want to delete your account? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration:
              InputDecoration(
                prefixIcon: const Icon(
                  Icons.person,
                  color: AppColors.iconMuted,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
                hintStyle: const TextStyle(color: AppColors.textHint),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 0,
                ),
              ).copyWith(
                prefixIcon: Icon(icon, color: AppColors.iconMuted, size: 20),
              ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyToggle(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Private Profile',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Only followers can see your profile details.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _isPrivate,
          onChanged: (value) {
            setState(() {
              _isPrivate = value;
            });
          },
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildBioField(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLines: 5,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
            hintStyle: const TextStyle(color: AppColors.textHint),
            contentPadding: const EdgeInsets.all(18),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildChangePasswordButton(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final currentPassword = _currentPasswordController.text.trim();
                  final newPassword = _newPasswordController.text.trim();
                  final confirmPassword = _confirmPasswordController.text.trim();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  if (currentPassword.isEmpty ||
                      newPassword.isEmpty ||
                      confirmPassword.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('All fields are required'),
                      ),
                    );
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('New passwords do not match'),
                      ),
                    );
                    return;
                  }

                  if (newPassword.length < 6) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                      ),
                    );
                    return;
                  }

                  final profileProvider =
                      Provider.of<ProfileProvider>(context, listen: false);

                  try {
                    await profileProvider.changePassword(
                      currentPassword: currentPassword,
                      newPassword: newPassword,
                    );

                    if (!mounted) return;

                    navigator.pop();

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );

                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                  } catch (e) {
                    if (!mounted) return;

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to change password: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Change Password',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.iconMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
