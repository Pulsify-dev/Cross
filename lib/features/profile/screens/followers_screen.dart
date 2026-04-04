import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _followers = [
    {
      'name': 'Alex Rivera',
      'subtitle': 'Follows you',
      'image': 'https://i.pravatar.cc/150?img=32',
      'isFollowing': true,
    },
    {
      'name': 'Jordan Smith',
      'subtitle': 'Follows you',
      'image': 'https://i.pravatar.cc/150?img=12',
      'isFollowing': false,
    },
    {
      'name': 'Sarah Chen',
      'subtitle': 'Follows you',
      'image': 'https://i.pravatar.cc/150?img=5',
      'isFollowing': false,
    },
    {
      'name': 'Marcus Wright',
      'subtitle': 'Follows you',
      'image': 'https://i.pravatar.cc/150?img=15',
      'isFollowing': true,
    },
    {
      'name': 'Riley Taylor',
      'subtitle': 'Follows you',
      'image': 'https://i.pravatar.cc/150?img=20',
      'isFollowing': false,
    },
  ];

  String get _query => _searchController.text.trim().toLowerCase();

  List<Map<String, dynamic>> get _filteredFollowers {
    if (_query.isEmpty) return _followers;
    return _followers
        .where((user) => (user['name'] as String).toLowerCase().contains(_query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /*void _toggleFollow(int index) {
    setState(() {
      _filteredFollowers[index]['isFollowing'] = !_filteredFollowers[index]['isFollowing'];
    });
  }*/

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFollowers;

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
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return _buildUserTile(
                    name: user['name'],
                    subtitle: user['subtitle'],
                    imageUrl: user['image'],
                    isFollowing: user['isFollowing'],
                    onPressed: () {
                      setState(() {
                        user['isFollowing'] = !user['isFollowing'];
                      });
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

  Widget _buildUserTile({
    required String name,
    required String subtitle,
    required String imageUrl,
    required bool isFollowing,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildFollowButton(
            label: isFollowing ? 'Following' : 'Follow',
            active: !isFollowing,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton({
    required String label,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? AppColors.primary : AppColors.surfaceElevated,
        foregroundColor: Colors.white,
        elevation: active ? 6 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}