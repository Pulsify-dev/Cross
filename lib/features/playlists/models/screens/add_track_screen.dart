import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../playlist_model.dart';
import 'package:cross/providers/playlist_provider.dart';

class AddTrackScreen extends StatelessWidget {
  const AddTrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Grab the playlist we are adding to
    final playlist = ModalRoute.of(context)!.settings.arguments as Playlist;

    // 2. Mock Data (Your "Spotify" Library)
    final List<String> allSongs = [
      "Blinding Lights", "Starboy", "Die For You", 
      "Heat Waves", "Stay", "Levitating"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Add to Playlist")),
      body: ListView.builder(
        itemCount: allSongs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(allSongs[index], style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.add, color: Colors.green),
            onTap: () {
              // 3. Tell the Brain (Provider) to add this song
              context.read<PlaylistProvider>().addTrackToPlaylist(playlist.id, allSongs[index]);
              
              // 4. Go back to the Details screen
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}