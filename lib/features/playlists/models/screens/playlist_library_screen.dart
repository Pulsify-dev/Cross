class PlaylistLibraryScreen extends StatelessWidget {
  const PlaylistLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Your Library", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = provider.playlists[index];
              return ListTile(
                leading: Container(
                  width: 50, height: 50,
                  color: Colors.grey[900],
                  child: const Icon(Icons.music_note, color: Colors.green),
                ),
                title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                // Show Privacy Status
                subtitle: Text(
                  playlist.isPublic ? "Public Set" : "🔒 Secret Set",
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.pushNamed(context, RouteNames.playlistDetails, arguments: playlist),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.pushNamed(context, RouteNames.createPlaylist),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}