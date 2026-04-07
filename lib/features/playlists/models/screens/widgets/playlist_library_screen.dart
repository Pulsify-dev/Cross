import 'package:flutter/material.dart';
import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/routes/route_names.dart';

class PlaylistLibraryScreen extends StatelessWidget {
  const PlaylistLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> mockData = [
      {'title': 'Top Hits 2026', 'tracks': '50 Tracks'},
      {'title': 'Workout Mix', 'tracks': '20 Tracks'},
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: AppBar(title: const Text('My Playlists'), backgroundColor: Colors.transparent),
      body: ListView.builder(
        itemCount: mockData.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.playlist_play, color: AppColors.primary),
            title: Text(mockData[index]['title']!, style: const TextStyle(color: Colors.white)),
            subtitle: Text(mockData[index]['tracks']!, style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.createPlaylist);
              },
            ),
          );
        },
      ),
    );
  }
}