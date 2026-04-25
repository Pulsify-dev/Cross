import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../feed/models/track.dart';
import '../../feed/models/comment.dart';
import '../../../providers/engagement_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/profile_provider.dart';

class TrackCommentsScreen extends StatefulWidget {
  final Track track;

  const TrackCommentsScreen({super.key, required this.track});

  @override
  State<TrackCommentsScreen> createState() => _TrackCommentsScreenState();
}

class _TrackCommentsScreenState extends State<TrackCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  Comment? _replyingTo;

  // Track which comments have their replies expanded
  final Map<String, bool> _expandedReplies = {};
  // Track which comments are currently loading replies
  final Map<String, bool> _loadingReplies = {};
  // Store fetched replies per comment id
  final Map<String, List<Comment>> _repliesMap = {};
  // Track locally deleted comments to hide them immediately
  final Set<String> _deletedCommentIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EngagementProvider>().fetchComments(widget.track.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleReplies(Comment comment) async {
    final commentId = comment.id;

    if (_expandedReplies[commentId] == true) {
      setState(() => _expandedReplies[commentId] = false);
      return;
    }

    // Fetch if not yet loaded
    if (!_repliesMap.containsKey(commentId)) {
      setState(() => _loadingReplies[commentId] = true);
      try {
        final result = await context
            .read<EngagementProvider>()
            .fetchCommentRepliesById(commentId);
        if (mounted) {
          setState(() {
            _repliesMap[commentId] = result;
            _loadingReplies[commentId] = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingReplies[commentId] = false);
      }
    }

    if (mounted) setState(() => _expandedReplies[commentId] = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<EngagementProvider>(
          builder: (context, provider, _) {
            final count = provider.commentsCount > 0
                ? provider.commentsCount
                : provider.comments.length;
            return Text('Comments ($count)');
          },
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

                // Only show top-level comments (no parent) and filter out deleted ones
                final parentComments = provider.comments
                    .where(
                      (c) =>
                          (c.parentCommentId == null ||
                              c.parentCommentId!.isEmpty) &&
                          !_deletedCommentIds.contains(c.id),
                    )
                    .toList();

                return ListView.builder(
                  itemCount: parentComments.length,
                  itemBuilder: (context, index) {
                    final comment = parentComments[index];
                    final isExpanded = _expandedReplies[comment.id] == true;
                    final isLoadingReplies =
                        _loadingReplies[comment.id] == true;
                    final replies = (_repliesMap[comment.id] ?? [])
                        .where((r) => !_deletedCommentIds.contains(r.id))
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCommentTile(comment, provider),

                        // Show Replies button
                        if (comment.repliesCount > 0 || replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 72, bottom: 4),
                            child: isLoadingReplies
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : TextButton.icon(
                                    onPressed: () => _toggleReplies(comment),
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 16,
                                    ),
                                    label: Text(
                                      isExpanded
                                          ? 'Hide replies'
                                          : 'View ${comment.repliesCount > 0 ? comment.repliesCount : replies.length} ${(comment.repliesCount == 1 || replies.length == 1) ? "reply" : "replies"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                          ),

                        // Replies list
                        if (isExpanded && replies.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child: Column(
                              children: replies
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
              const SizedBox(width: 8),
              if (!isReply)
                _buildInteractionButton(
                  icon: Icons.reply,
                  label: 'Reply',
                  onTap: () {
                    setState(() => _replyingTo = comment);
                    FocusScope.of(context).requestFocus();
                  },
                ),
              const Spacer(),
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  final isOwnComment =
                      profileProvider.profile?.id == comment.userId;
                  if (!isOwnComment) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => _showEditDialog(comment, provider),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () => _showDeleteConfirm(
                          comment,
                          provider,
                          parentCommentId: comment.parentCommentId,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  );
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
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    color ??
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Comment comment, EngagementProvider provider) {
    final TextEditingController editController = TextEditingController(
      text: comment.text,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new comment...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (editController.text.isNotEmpty) {
                provider.updateComment(
                  widget.track.id,
                  comment.id,
                  editController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    Comment comment,
    EngagementProvider provider, {
    String? parentCommentId,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Optimistic delete: add to hidden set and decrement count
              setState(() {
                _deletedCommentIds.add(comment.id);
              });

              if (parentCommentId != null) {
                // Deleting a reply
                provider.adjustCommentsCount(-1);

                // Also remove from local map if it exists
                if (_repliesMap.containsKey(parentCommentId)) {
                  setState(() {
                    _repliesMap[parentCommentId]!.removeWhere(
                      (r) => r.id == comment.id,
                    );
                  });
                }

                try {
                  await provider.deleteCommentOnly(comment.id);
                } catch (_) {
                  // Restore on failure
                  if (mounted) {
                    provider.adjustCommentsCount(1);
                    setState(() {
                      _deletedCommentIds.remove(comment.id);
                    });
                  }
                }
              } else {
                // Deleting a parent
                final knownReplies = _repliesMap[comment.id] ?? [];
                final totalToDelete = 1 + knownReplies.length;
                provider.adjustCommentsCount(-totalToDelete);

                // Add all replies to deleted set too
                setState(() {
                  for (final r in knownReplies) {
                    _deletedCommentIds.add(r.id);
                  }
                });

                try {
                  for (final reply in knownReplies) {
                    await provider.deleteCommentOnly(reply.id);
                  }
                  await provider.deleteComment(widget.track.id, comment.id);
                } catch (_) {
                  // Restore on failure (best effort)
                  if (mounted) {
                    provider.adjustCommentsCount(totalToDelete);
                    setState(() {
                      _deletedCommentIds.remove(comment.id);
                      for (final r in knownReplies) {
                        _deletedCommentIds.remove(r.id);
                      }
                    });
                  }
                }

                if (!mounted) return;
                setState(() {
                  _repliesMap.remove(comment.id);
                  _expandedReplies.remove(comment.id);
                  _loadingReplies.remove(comment.id);
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
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
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    final player = context.read<PlayerProvider>();
    final timestamp = player.currentTrack?.id == widget.track.id
        ? player.position
        : Duration.zero;

    final currentUserId =
        context.read<ProfileProvider>().profile?.id ?? 'unknown';
    final parentId = _replyingTo?.id;
    final text = _commentController.text;

    _commentController.clear();
    final replyTarget = _replyingTo;
    setState(() => _replyingTo = null);
    FocusScope.of(context).unfocus();

    final engagementProvider = context.read<EngagementProvider>();

    await engagementProvider.addComment(
      widget.track.id,
      currentUserId,
      text,
      timestamp,
      parentCommentId: parentId,
    );

    // If it was a reply, refresh that comment's replies if already expanded
    if (replyTarget != null && _expandedReplies[replyTarget.id] == true) {
      final result =
          await engagementProvider.fetchCommentRepliesById(replyTarget.id);
      if (mounted) {
        setState(() => _repliesMap[replyTarget.id] = result);
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}
