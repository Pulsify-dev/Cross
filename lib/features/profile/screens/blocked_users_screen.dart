import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _blockedUsers = [
    {
      'name': 'Spam User',
      'subtitle': 'Blocked',
      'image': 'https://i.pravatar.cc/150?img=1',
    },
    {
      'name': 'Troll Account',
      'subtitle': 'Blocked',
      'image': 'https://i.pravatar.cc/150?img=2',
    },
    {
      'name': 'Fake Profile',
      'subtitle': 'Blocked',
      'image': 'https://i.pravatar.cc/150?img=3',
    },
  ];

  String get _query => _searchController.text.trim().toLowerCase();

  List<Map<String, dynamic>> get _filteredBlockedUsers {
    if (_query.isEmpty) return _blockedUsers;
    return _blockedUsers.where((user) {
      return user['name'].toLowerCase().contains(_query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: _filteredBlockedUsers.isEmpty
                ? Center(
                    child: Text(
                      'No blocked users found',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredBlockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredBlockedUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user['image']),
                          radius: 24,
                        ),
                        title: Text(
                          user['name'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          user['subtitle'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement unblock functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Unblock ${user['name']}'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Unblock'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}