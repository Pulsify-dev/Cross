import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/feed/screens/home_screen.dart';
import 'package:cross/features/search/screens/search_screen.dart';
import 'package:cross/features/library/screens/library_screen.dart';
import 'package:cross/features/messages/screens/messages_screen.dart';
import 'package:cross/features/profile/screens/user_profile_screen.dart';
import 'package:cross/features/feed/screens/activity_feed_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  late final List<Widget> _screens = [
    HomeScreen(
      onProfileTap: () {
        setState(() {
          _selectedIndex = 5; // Switch to Profile tab
        });
      },
    ),
    const ActivityFeedScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const MessagesScreen(),
    const UserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    bool showBadge = false,
  }) {
    final selected = _selectedIndex == index;
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (showBadge)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.navBarBackground,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(icon: Icons.home, label: 'Home', index: 0),
            _navItem(icon: Icons.feed, label: 'Activity', index: 1),
            _navItem(icon: Icons.search, label: 'Search', index: 2),
            _navItem(icon: Icons.library_music, label: 'Playlists', index: 3),
            _navItem(
              icon: Icons.chat_bubble,
              label: 'Messages',
              index: 4,
              showBadge: true,
            ),
            _navItem(icon: Icons.person, label: 'Profile', index: 5),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
