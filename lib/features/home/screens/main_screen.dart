import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/feed/screens/home_screen.dart';
import 'package:cross/features/search/screens/search_screen.dart';
import 'package:cross/features/library/screens/library_screen.dart';
import 'package:cross/providers/feed_provider.dart';
import 'package:cross/features/feed/screens/feed_screen.dart';
import 'package:cross/features/player/widgets/mini_player.dart';
import 'package:cross/providers/subscription_provider.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const FeedScreen(),
    const _UpgradeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 3) {
        context.read<FeedProvider>().fetchFeed();
        context.read<FeedProvider>().fetchDiscoveryFeed();
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    bool showBadge = false,
    Key? tabKey,
  }) {
    final selected = _selectedIndex == index;
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        key: tabKey,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedIndex != 3) const MiniPlayer(),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.navBarBackground,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _navItem(
                  icon: Icons.home,
                  label: 'Home',
                  index: 0,
                  tabKey: const Key('nav_home_tab'),
                ),
                _navItem(
                  icon: Icons.search,
                  label: 'Search',
                  index: 1,
                  tabKey: const Key('nav_search_tab'),
                ),
                _navItem(
                  icon: Icons.library_music,
                  label: 'Library',
                  index: 2,
                  tabKey: const Key('nav_library_tab'),
                ),
                _navItem(
                  icon: Icons.dynamic_feed,
                  label: 'Feed',
                  index: 3,
                  tabKey: const Key('nav_feed_tab'),
                ),
                _navItem(
                  icon: Icons.workspace_premium,
                  label: 'Upgrade',
                  index: 4,
                  tabKey: const Key('nav_upgrade_tab'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }
}

class _UpgradeScreen extends StatelessWidget {
  const _UpgradeScreen();

@override
  Widget build(BuildContext context) {
    // This connects your screen to the 'brain' (Provider)
    final subProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: subProvider.isLoading 
          ? const CircularProgressIndicator() 
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Plan: ${subProvider.currentPlan}', 
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Usage: ${subProvider.sub?.usedTracks ?? 0} / ${subProvider.sub?.trackLimit ?? 10} tracks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 24),

                if (!subProvider.isPremium)
                  ElevatedButton(
                    onPressed: () => subProvider.upgradeAccount(), // Starts the real upgrade
                    child: const Text('Upgrade to Artist Pro'),
                  )
                else
                  TextButton(
                    onPressed: () => subProvider.downgradeAccount(), // Starts the cancellation
                    child: const Text('Cancel Subscription', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
      ),
    );
  }
}