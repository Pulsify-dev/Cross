import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/playlist_provider.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final TextEditingController controller = TextEditingController();
  bool _isPublic = true; // For Module 7 Privacy requirement

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Create New Set")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Playlist Name",
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            
            // This handles the "Secret vs Public" requirement
            SwitchListTile(
              title: const Text("Public Playlist", style: TextStyle(color: Colors.white)),
              value: _isPublic,
              onChanged: (bool value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  context.read<PlaylistProvider>().addPlaylist(
                    controller.text, 
                    _isPublic
                  );
                  
                  Navigator.pop(context); // Go back to Library
                }
              },
              child: const Text("Create Set"),
            ),
          ],
        ),
      ),
    );
  }
}