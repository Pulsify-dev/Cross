import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/playlist_model.dart';
import '../../../providers/playlist_provider.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  const PlaylistDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Grab the Playlist object passed from the Library
    final playlist = ModalRoute.of(context)!.settings.arguments as Playlist;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          // Edit Button (Top Right)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(context, '/editPlaylist', arguments: playlist),
          ),
        ],
      ),
      body: Column(
        children: [
          // 2. Privacy Header (Secret Token Section)
          if (!playlist.isPublic)
            Container(
              color: Colors.amber.withOpacity(0.1),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Secret Token: ${playlist.secretToken}",
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () { /* Add Copy to Clipboard Logic */ },
                    child: const Text("Copy"),
                  )
                ],
              ),
            ),

          // 3. The Tracks List (Drag & Drop Sequencing)
          Expanded(
            child: Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                // Find the latest version of this playlist in the provider
                final currentPlaylist = provider.playlists.firstWhere((p) => p.id == playlist.id);

                if (currentPlaylist.tracks.isEmpty) {
                  return const Center(child: Text("No tracks in this set."));
                }

                return ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderTracks(currentPlaylist.id, oldIndex, newIndex);
                  },
                  children: [
                    for (int i = 0; i < currentPlaylist.tracks.length; i++)
                      ListTile(
                        key: ValueKey(currentPlaylist.tracks[i]),
                        leading: const Icon(Icons.music_note, color: Colors.grey),
                        title: Text(currentPlaylist.tracks[i], style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      // 4. Floating Action Button to Add Tracks
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.pushNamed(context, '/addTrack', arguments: playlist),
        child: const Icon(Icons.add),
      ),
    );
  }
}