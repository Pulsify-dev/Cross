import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/social/widgets/social_list_state_view.dart';
import 'package:cross/features/social/widgets/social_user_tile.dart';
import 'package:cross/providers/social_provider.dart';
import 'package:cross/routes/route_names.dart';
import 'package:provider/provider.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String get _query => _searchController.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().loadList(
            SocialListType.blocked,
            userId: context.read<SocialProvider>().currentUserId,
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
        title: const Text('Blocked Users'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search blocked users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.surfaceSoft,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: Consumer<SocialProvider>(
              builder: (context, provider, _) {
                final users = provider.blockedUsers
                    .where((user) =>
                        _query.isEmpty ||
                        user.displayName.toLowerCase().contains(_query) ||
                        user.username.toLowerCase().contains(_query))
                    .toList();

                if (provider.isListLoading(SocialListType.blocked)) {
                  return const Center(child: CircularProgressIndicator());
                }

                final error = provider.listError(SocialListType.blocked);
                if (error != null && users.isEmpty) {
                  return SocialListStateView(
                    icon: Icons.error_outline,
                    title: 'Could not load blocked users',
                    message: error,
                    actionLabel: 'Retry',
                    onAction: () => provider.loadList(
                      SocialListType.blocked,
                      userId: provider.currentUserId,
                    ),
                  );
                }

                if (users.isEmpty) {
                  return const SocialListStateView(
                    icon: Icons.block,
                    title: 'No blocked users',
                    message: 'Users you block will appear here.',
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return SocialUserTile(
                      name: user.displayName,
                      subtitle: 'Blocked user',
                      avatarUrl: user.avatarUrl,
                      actionLabel: 'Unblock',
                      actionActive: true,
                      isActionLoading: provider.isMutatingRelationship,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.publicProfile,
                        arguments: user.id,
                      ),
                      onAction: () => provider.unblockUser(user.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}