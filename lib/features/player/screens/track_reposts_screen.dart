import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../feed/models/track.dart';
import '../../../providers/engagement_provider.dart';
import '../widgets/mini_player.dart';

class TrackRepostsScreen extends StatefulWidget {
  final Track track;

  const TrackRepostsScreen({super.key, required this.track});

  @override
  State<TrackRepostsScreen> createState() => _TrackRepostsScreenState();
}

class _TrackRepostsScreenState extends State<TrackRepostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EngagementProvider>().fetchTrackReposts(widget.track.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reposted by')),
      body: Column(
        children: [
          Expanded(
            child: Consumer<EngagementProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.trackReposts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.trackReposts.isEmpty) {
                  return const Center(child: Text('No reposts yet.'));
                }

                return ListView.builder(
                  itemCount: provider.trackReposts.length,
                  itemBuilder: (context, index) {
                    final user = provider.trackReposts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      trailing: TextButton(
                        onPressed: () {
                           Navigator.pushNamed(
                            context,
                            '/public-profile',
                            arguments: user.id,
                          );
                        },
                        child: Text(
                          'View Profile',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
