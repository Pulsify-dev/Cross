import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/social/widgets/social_list_state_view.dart';
import 'package:cross/features/social/widgets/social_user_tile.dart';
import 'package:cross/providers/social_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MutualFollowersScreen extends StatefulWidget {
  const MutualFollowersScreen({super.key, required this.userId});

  final String userId;

  @override
  State<MutualFollowersScreen> createState() => _MutualFollowersScreenState();
}

class _MutualFollowersScreenState extends State<MutualFollowersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String get _query => _searchController.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().loadList(
            SocialListType.mutualFollowers,
            userId: widget.userId,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutual Followers'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<SocialProvider>(
                builder: (context, provider, _) {
                  final users = provider.mutualFollowers
                      .where((user) =>
                          _query.isEmpty ||
                          user.displayName.toLowerCase().contains(_query) ||
                          user.username.toLowerCase().contains(_query))
                      .toList();

                  if (provider.isListLoading(SocialListType.mutualFollowers)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final error = provider.listError(SocialListType.mutualFollowers);
                  if (error != null && users.isEmpty) {
                    return SocialListStateView(
                      icon: Icons.error_outline,
                      title: 'Could not load mutual followers',
                      message: error,
                      actionLabel: 'Retry',
                      onAction: () => provider.loadList(
                        SocialListType.mutualFollowers,
                        userId: widget.userId,
                      ),
                    );
                  }

                  if (users.isEmpty) {
                    return const SocialListStateView(
                      icon: Icons.group_outlined,
                      title: 'No mutual followers yet',
                      message: 'When you share followers, they will appear here.',
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return SocialUserTile(
                        name: user.displayName,
                        subtitle: user.subtitle,
                        avatarUrl: user.avatarUrl,
                        actionLabel: user.isFollowing ? 'Following' : 'Follow',
                        actionActive: !user.isFollowing,
                        isActionLoading: provider.isMutatingRelationship,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.publicProfile,
                          arguments: user.id,
                        ),
                        onAction: () {
                          if (user.isFollowing) {
                            provider.unfollowUser(user.id);
                          } else {
                            provider.followUser(user.id);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Search mutual followers',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
