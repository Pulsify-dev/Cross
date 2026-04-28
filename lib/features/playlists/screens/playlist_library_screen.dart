import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../../providers/subscription_provider.dart'; 
import '../../../routes/route_names.dart';
import '../../../providers/auth_provider.dart'; 

class PlaylistLibraryScreen extends StatelessWidget {
  const PlaylistLibraryScreen({super.key});

  // Helper to show the SoundCloud-style "Upgrade" sheet
  void _showPremiumUpsell(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            const Text(
              "SoundCloud Go+",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "This playlist is for premium members only. Upgrade now to unlock all tracks.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Connect to Postman POST /subscriptions/upgrade
                context.read<SubscriptionProvider>().upgradeAccount();
                Navigator.pop(context);
              },
              child: const Text("UPGRADE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUserPremium = context.watch<SubscriptionProvider>().isPremium;
    final authProvider = Provider.of<AuthProvider>(context);
    final playlistProv = context.watch<PlaylistProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("My Playlists")),
      body: playlistProv.playlists.isEmpty
          ? const Center(child: Text("No playlists yet."))
          : ListView.builder(
              itemCount: playlistProv.playlists.length,
              itemBuilder: (context, index) {
                final item = playlistProv.playlists[index];
                return ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: Row(
                    children: [
                      Text(item.title),
                      const SizedBox(width: 8),
                      // SoundCloud GO+ Badge
                      if (item.isPremium) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "GO+",
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(item.description ?? ""),
                  onTap: () {
                    // Logic Check: If playlist is premium and user is not, block access
                    if (item.isPremium && !isUserPremium) {
                      _showPremiumUpsell(context);
                    } else {
                      Navigator.pushNamed(
                        context,
                        RouteNames.playlistDetails,
                        arguments: item,
                      );
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RouteNames.editPlaylist,
                          arguments: item,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => playlistProv.deletePlaylist(authProvider.token ?? "", item.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, RouteNames.createPlaylist),
        child: const Icon(Icons.add),
      ),
    );
  }
}