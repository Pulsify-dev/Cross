import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../feed/models/track.dart';
import '../../feed/models/comment.dart';
import '../../../providers/engagement_provider.dart';
import '../../../providers/player_provider.dart';

class TrackCommentsScreen extends StatefulWidget {
  final Track track;

  const TrackCommentsScreen({super.key, required this.track});

  @override
  State<TrackCommentsScreen> createState() => _TrackCommentsScreenState();
}

class _TrackCommentsScreenState extends State<TrackCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EngagementProvider>().fetchComments(widget.track.id);
    });
  }

  Comment? _replyingTo;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<EngagementProvider>(
          builder: (context, provider, _) =>
              Text('Comments (${provider.comments.length})'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<EngagementProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.comments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first!'),
                  );
                }

                // Group replies by parentCommentId
                final parentComments = provider.comments
                    .where((c) => c.parentCommentId == null)
                    .toList();
                final replies = provider.comments
                    .where((c) => c.parentCommentId != null)
                    .toList();

                return ListView.builder(
                  itemCount: parentComments.length,
                  itemBuilder: (context, index) {
                    final comment = parentComments[index];
                    final commentReplies = replies
                        .where((r) => r.parentCommentId == comment.id)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCommentTile(comment, provider),
                        if (commentReplies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Column(
                              children: commentReplies
                                  .map(
                                    (reply) => _buildCommentTile(
                                      reply,
                                      provider,
                                      isReply: true,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const Divider(height: 1),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentTile(
    Comment comment,
    EngagementProvider provider, {
    bool isReply = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: isReply ? 16 : 20,
        backgroundImage: comment.userProfileImageUrl != null
            ? NetworkImage(comment.userProfileImageUrl!)
            : null,
        child: comment.userProfileImageUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        comment.username,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.text, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _formatDuration(comment.timestampInTrack),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d').format(comment.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              _buildInteractionButton(
                icon: comment.isLiked ? Icons.favorite : Icons.favorite_border,
                label: comment.likeCount.toString(),
                color: comment.isLiked
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                onTap: () =>
                    provider.toggleCommentLike(widget.track.id, comment),
              ),
              if (!isReply)
                _buildInteractionButton(
                  icon: Icons.reply,
                  label: 'Reply',
                  onTap: () {
                    setState(() => _replyingTo = comment);
                    FocusScope.of(context).requestFocus();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  color ??
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    color ??
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replying to ${_replyingTo!.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _replyingTo = null),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            bottom: true,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? 'Write a reply...'
                          : 'Add a comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      final player = context.read<PlayerProvider>();
                      final timestamp =
                          player.currentTrack?.id == widget.track.id
                          ? player.position
                          : Duration.zero;

                      context.read<EngagementProvider>().addComment(
                        widget.track.id,
                        'current_user_id',
                        _commentController.text,
                        timestamp,
                        parentCommentId: _replyingTo?.id,
                      );
                      _commentController.clear();
                      setState(() => _replyingTo = null);
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}
