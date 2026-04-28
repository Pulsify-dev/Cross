import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../../providers/auth_provider.dart'; 

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  void _submit() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title!"))
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    // THIS PRINT WILL TELL US IF THE KEY IS BROKEN
    debugPrint("DEBUG: Attempting create with Token: ${auth.token}");
    debugPrint("DEBUG: Attempting create with Title: $title");

    final success = await playlistProvider.createPlaylist(auth.token ?? "", title);
    
    if (success) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create. Check Debug Console!"))
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Playlist")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController, 
              decoration: const InputDecoration(labelText: "Playlist Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController, 
              decoration: const InputDecoration(labelText: "Description (Optional)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit, 
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}