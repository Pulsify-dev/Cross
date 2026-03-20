import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _following = [
    {
      'name': 'Alex Rivers',
      'handle': '@alex_music',
      'image': 'https://i.pravatar.cc/150?img=32',
      'isOnline': true,
      'isFollowing': true,
    },
    {
      'name': 'Jordan Beats',
      'handle': '@jordan_b',
      'image': 'https://i.pravatar.cc/150?img=12',
      'isOnline': false,
      'isFollowing': true,
    },
    {
      'name': 'Luna Sky',
      'handle': '@luna_official',
      'image': 'https://i.pravatar.cc/150?img=47',
      'isOnline': false,
      'isFollowing': true,
    },
    {
      'name': 'Marcus Vibe',
      'handle': '@marcus_vibe',
      'image': 'https://i.pravatar.cc/150?img=15',
      'isOnline': false,
      'isFollowing': true,
    },
    {
      'name': 'Chloe Synth',
      'handle': '@chloe_s',
      'image': 'https://i.pravatar.cc/150?img=25',
      'isOnline': false,
      'isFollowing': true,
    },
    {
      'name': 'Acoustic Soul',
      'handle': '@soul_acoustic',
      'image': 'https://i.pravatar.cc/150?img=52',
      'isOnline': false,
      'isFollowing': true,
    },
  ];

  String get _query => _searchController.text.trim().toLowerCase();

  List<Map<String, dynamic>> get _filteredFollowing {
    if (_query.isEmpty) return _following;
    return _following.where((user) {
      final name = (user['name'] as String).toLowerCase();
      final handle = (user['handle'] as String).toLowerCase();
      return name.contains(_query) || handle.contains(_query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFollowing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {},
          ),
        ],
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
                    handle: user['handle'],
                    imageUrl: user['image'],
                    isOnline: user['isOnline'],
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
          hintText: 'Search following artists...',
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
    required String handle,
    required String imageUrl,
    required bool isOnline,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(imageUrl),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceSoft,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
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
                  handle,
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