import 'package:cross/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/playlist_provider.dart';
import '../models/playlist_model.dart';

class EditPlaylistScreen extends StatefulWidget {
  final Playlist playlist; // This is the data being "caught"
  const EditPlaylistScreen({super.key, required this.playlist});

  @override
  State<EditPlaylistScreen> createState() => _EditPlaylistScreenState();
}

class _EditPlaylistScreenState extends State<EditPlaylistScreen> {
  // We use late so we can initialize them in initState
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    // Use widget.playlist directly - no more ModalRoute needed!
    _titleController = TextEditingController(text: widget.playlist.title);
    _descController = TextEditingController(text: widget.playlist.description);
  }

  // Always dispose your controllers to save memory
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

 void _saveChanges() async {
    if (_titleController.text.isEmpty) return;
    
    await context.read<PlaylistProvider>().updatePlaylist(
      context.read<AuthProvider>().token ?? '',
      widget.playlist.id,
      _titleController.text,
      _descController.text, 
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Playlist")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController, 
              decoration: const InputDecoration(labelText: "Title")
            ),
            TextField(
              controller: _descController, 
              decoration: const InputDecoration(labelText: "Description")
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges, 
              child: const Text("Save Changes")
            ),
          ],
        ),
      ),
    );
  }
}