import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/route_names.dart';
import '../../../providers/profile_provider.dart';
import '../../profile/models/profile_data.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadMyProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Library'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(RouteNames.profile),
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileProvider, _) {
                      final profile = profileProvider.profile;
                      return CircleAvatar(
                        radius: 16,
                        backgroundImage: avatarImage(
                          path: profile?.avatarPath,
                          bytes: profile?.avatarBytes,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: profile?.avatarPath == null && profile?.avatarBytes == null
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLibraryItem(
            context,
            icon: Icons.favorite,
            title: 'Liked Tracks',
            subtitle: 'Your favorite sounds in one place',
            route: RouteNames.likedTracks,
          ),
          const SizedBox(height: 16),
          _buildLibraryItem(
            context,
            icon: Icons.history,
            title: 'Listening History',
            subtitle: 'Relive your recent discoveries',
            route: RouteNames.history,
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
