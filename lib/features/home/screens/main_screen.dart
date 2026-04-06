import 'package:flutter/material.dart';
import '../../feed/screens/home_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../library/screens/library_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../player/widgets/mini_player.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const SearchScreen(),
      const LibraryScreen(), // Serves as Playlists here
      const MessagesScreen(),
      const Center(child: Text('Profile Screen')), // Placeholder for Profile
    ];

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_filled),
        label: 'Home',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.library_music_rounded),
        label: 'Library',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_rounded),
        label: 'Messages',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
