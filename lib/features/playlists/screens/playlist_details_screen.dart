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
    
    final currentPlaylist = provider.playlists.firstWhere(
      (p) => p.id == playlist.id, 
      orElse: () => playlist
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlaylist.title),
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
          ? const Center(child: Text("No tracks in this playlist."))
          : ListView.builder(
              itemCount: currentPlaylist.trackIds.length,
              itemBuilder: (context, index) {
                final trackId = currentPlaylist.trackIds[index];
                return ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")),
                  title: Text("Track $trackId"),
                  trailing: const Icon(Icons.play_arrow),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context, 
          RouteNames.addTrack, 
          arguments: currentPlaylist,
        ),
        child: const Icon(Icons.library_add), 
      ),
    );
  }
}