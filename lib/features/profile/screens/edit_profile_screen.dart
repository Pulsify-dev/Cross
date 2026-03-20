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
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late String _avatarPath;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    _avatarPath = profile.avatarPath ?? '';
    _avatarBytes = profile.avatarBytes;
    _usernameController = TextEditingController(text: profile.username);
    _bioController = TextEditingController(text: profile.bio);
    _emailController = TextEditingController(text: profile.email);
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

    setState(() {
      _avatarBytes = bytes;
      _avatarPath = '';
    });

    profileProvider.updateProfile(
      profileProvider.profile.copyWith(
        avatarBytes: bytes,
        avatarPath: null,
        username: _usernameController.text,
        bio: _bioController.text,
        email: _emailController.text,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
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
                          onTap: _pickImage,
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
                      onTap: _pickImage,
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
                label: 'Username',
                controller: _usernameController,
                icon: Icons.person,
              ),
              const SizedBox(height: 20),

              _buildBioField(context),
              const SizedBox(height: 20),

              _buildFormField(
                context,
                label: 'Email',
                controller: _emailController,
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              _buildChangePasswordButton(context),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  final profileProvider = Provider.of<ProfileProvider>(
                    context,
                    listen: false,
                  );
                  profileProvider.updateProfile(
                    profileProvider.profile.copyWith(
                      avatarPath: _avatarPath.isNotEmpty ? _avatarPath : null,
                      avatarBytes: _avatarBytes,
                      username: _usernameController.text,
                      bio: _bioController.text,
                      email: _emailController.text,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes saved!')),
                  );
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
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
                onPressed: () => Navigator.pop(context),
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
