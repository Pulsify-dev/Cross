import 'package:flutter/material.dart';
import '../models/playlist_model.dart';

class AddTrackScreen extends StatelessWidget {
  final Playlist playlist;
  const AddTrackScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add to ${playlist.title}")),
      body: const Center(child: Text("Track Search/List Logic Here")),
    );
  }
}