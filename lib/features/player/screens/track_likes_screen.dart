import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../feed/models/track.dart';
import '../../../providers/engagement_provider.dart';
import '../../../routes/route_names.dart';
import '../widgets/mini_player.dart';

class TrackLikesScreen extends StatefulWidget {
  final Track track;

  const TrackLikesScreen({super.key, required this.track});

  @override
  State<TrackLikesScreen> createState() => _TrackLikesScreenState();
}

class _TrackLikesScreenState extends State<TrackLikesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EngagementProvider>().fetchTrackLikes(widget.track.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liked by')),
      body: Column(
        children: [
          Expanded(
            child: Consumer<EngagementProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.trackLikes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.trackLikes.isEmpty) {
                  return const Center(child: Text('No likes yet.'));
                }

                return ListView.builder(
                  itemCount: provider.trackLikes.length,
                  itemBuilder: (context, index) {
                    final user = provider.trackLikes[index];
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
                            RouteNames.publicProfile,
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
