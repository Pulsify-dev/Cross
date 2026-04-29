import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../feed/models/track.dart';

class PlaylistSelectorSheet extends StatefulWidget {
  final Track track;
  const PlaylistSelectorSheet({super.key, required this.track});

  @override
  State<PlaylistSelectorSheet> createState() => _PlaylistSelectorSheetState();
}

class _PlaylistSelectorSheetState extends State<PlaylistSelectorSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistProvider>().fetchPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final playlists = playlistProvider.playlists;

    return Container(
      // FIXED: Added a maximum height constraint to stop the 760px overflow
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7, 
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Keep the sheet as small as possible
        children: [
          const Text(
            'Add to Playlist',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Colors.white
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24),
          
          if (playlistProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(30.0),
              child: CircularProgressIndicator(color: Colors.orange),
            )
          else if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30.0),
              child: Text(
                'No playlists found.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            // FIXED: Wrapped in Flexible AND used shrinkWrap
            Flexible(
              child: ListView.builder(
                shrinkWrap: true, 
                // FIXED: physics ensures the list captures the touch event
                physics: const ClampingScrollPhysics(), 
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    leading: const Icon(Icons.playlist_play, color: Colors.white),
                    title: Text(
                      playlist.title!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      // Debug log to confirm tap is working
                      debugPrint("TAP DETECTED: Adding to ${playlist.title}");

                      final success = await playlistProvider.addTrackToPlaylist(
                        playlist.id!, 
                        widget.track.id!,
                      );
                      
                      if (context.mounted && success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${playlist.title!}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}