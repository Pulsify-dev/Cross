import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cross/features/playlists/models/playlist_model.dart';
import 'package:cross/providers/playlist_provider.dart';

class EditPlaylistScreen extends StatelessWidget {
  final Playlist playlist;

  const EditPlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: playlist.name);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Playlist")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: controller),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<PlaylistProvider>().updatePlaylist(playlist.id, controller.text);
                Navigator.pop(context);
              },
              child: const Text("Update Name"),
            ),
          ],
        ),
      ),
    );
  }
}