import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/social/widgets/social_list_state_view.dart';
import 'package:cross/features/social/widgets/social_user_tile.dart';
import 'package:cross/providers/social_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:provider/provider.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({
    super.key,
    this.targetUserId,
  });

  final String? targetUserId;

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _targetUserId;

  String get _query => _searchController.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<SocialProvider>();
      _targetUserId =
          widget.targetUserId != null && widget.targetUserId!.trim().isNotEmpty
              ? widget.targetUserId!.trim()
              : provider.currentUserId;
      provider.loadList(
        SocialListType.followers,
        userId: _targetUserId ?? provider.currentUserId,
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
        title: const Text('Followers'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                  final users = provider.followers
                      .where((user) =>
                          _query.isEmpty ||
                          user.displayName.toLowerCase().contains(_query) ||
                          user.username.toLowerCase().contains(_query))
                      .toList();

                  if (provider.isListLoading(SocialListType.followers)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final error = provider.listError(SocialListType.followers);
                  if (error != null && users.isEmpty) {
                    return SocialListStateView(
                      icon: Icons.error_outline,
                      title: 'Could not load followers',
                      message: error,
                      actionLabel: 'Retry',
                      onAction: () => provider.loadList(
                        SocialListType.followers,
                        userId: _targetUserId ?? provider.currentUserId,
                      ),
                    );
                  }

                  if (users.isEmpty) {
                    return const SocialListStateView(
                      icon: Icons.people_outline,
                      title: 'No followers yet',
                      message: 'Followers will show up here when people follow you.',
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelf = user.id == provider.currentUserId;
                      return SocialUserTile(
                        name: user.displayName,
                        subtitle: user.subtitle,
                        avatarUrl: user.avatarUrl,
                        actionLabel: user.isFollowing ? 'Following' : 'Follow',
                        actionActive: !user.isFollowing,
                        showAction: !isSelf,
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.publicProfile,
                          arguments: user.id,
                        ),
                        onAction: isSelf
                            ? null
                            : () {
                          if (user.isFollowing) {
                            provider.unfollowUser(user.id);
                          } else {
                            provider.followUser(user.id);
                          }
                        },
                        isActionLoading: provider.isMutatingRelationship,
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
          hintText: 'Search followers',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

}