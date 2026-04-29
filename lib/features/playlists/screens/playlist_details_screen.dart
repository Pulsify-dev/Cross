import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist_model.dart';
import '../../../routes/route_names.dart';
import '../../../providers/playlist_provider.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailsScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaylistProvider>();
    
    // Finds the updated version of this playlist from the provider
    final currentPlaylist = provider.playlists.firstWhere(
      (p) => p.id == playlist.id, 
      orElse: () => playlist
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlaylist.title!), // FIXED: Added !
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context, 
              RouteNames.editPlaylist, 
              arguments: currentPlaylist
            ),
          ),
        ],
      ),
      body: currentPlaylist.trackIds.isEmpty
          ? const Center(child: Text("No tracks in this playlist.", style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              itemCount: currentPlaylist.trackIds.length,
              itemBuilder: (context, index) {
                final trackId = currentPlaylist.trackIds[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    "Track ID: $trackId", // Later you can map this to a Track name
                    style: const TextStyle(color: Colors.white),
                  ),
                  // ADDED: Remove Track button to make the feature functional
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: () async {
                      final success = await provider.removeTrack(currentPlaylist.id!, trackId);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Track removed from playlist"))
                        );
                      }
                    },
                  ),
                  onTap: () {
                    // This is where you'll trigger the Audio Player in Module 8
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => Navigator.pushNamed(
          context, 
          RouteNames.addTrack, 
          arguments: currentPlaylist,
        ),
        child: const Icon(Icons.library_add, color: Colors.white), 
      ),
    );
  }
}