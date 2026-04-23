import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/social/widgets/social_list_state_view.dart';
import 'package:cross/features/social/widgets/social_user_tile.dart';
import 'package:cross/providers/social_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SuggestedUsersScreen extends StatefulWidget {
  const SuggestedUsersScreen({super.key});

  @override
  State<SuggestedUsersScreen> createState() => _SuggestedUsersScreenState();
}

class _SuggestedUsersScreenState extends State<SuggestedUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String get _query => _searchController.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<SocialProvider>();
      provider.loadList(SocialListType.suggested, userId: provider.currentUserId);
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
        title: const Text('Suggested Users'),
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
                  final users = provider.suggestedUsers
                      .where((user) =>
                          _query.isEmpty ||
                          user.displayName.toLowerCase().contains(_query) ||
                          user.username.toLowerCase().contains(_query))
                      .toList();

                  if (provider.isListLoading(SocialListType.suggested)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final error = provider.listError(SocialListType.suggested);
                  if (error != null && users.isEmpty) {
                    return SocialListStateView(
                      icon: Icons.error_outline,
                      title: 'Could not load suggestions',
                      message: error,
                      actionLabel: 'Retry',
                      onAction: () => provider.loadList(
                        SocialListType.suggested,
                        userId: provider.currentUserId,
                      ),
                    );
                  }

                  if (users.isEmpty) {
                    return const SocialListStateView(
                      icon: Icons.person_search,
                      title: 'No suggestions right now',
                      message: 'Try again later for fresh recommendations.',
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return SocialUserTile(
                        name: user.displayName,
                        subtitle: 'Suggested for you',
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
          hintText: 'Search suggested users',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
