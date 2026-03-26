import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/discussion_model.dart';
import '../../../services/projects_service.dart';
import '../../../utils/time_ago.dart';

class ProjectLinkedDiscussionsTab extends StatefulWidget {
  final Project project;
  final bool isOwner;

  const ProjectLinkedDiscussionsTab({
    super.key,
    required this.project,
    required this.isOwner,
  });

  @override
  State<ProjectLinkedDiscussionsTab> createState() =>
      _ProjectLinkedDiscussionsTabState();
}

class _ProjectLinkedDiscussionsTabState
    extends State<ProjectLinkedDiscussionsTab> {
  List<Discussion> _discussions = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final discussions =
          await ProjectsService.getLinkedDiscussions(widget.project.id);
      if (mounted) {
        setState(() {
          _discussions = discussions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load discussions'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDiscussions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_discussions.isEmpty) {
      return _buildEmpty(context);
    }

    return RefreshIndicator(
      onRefresh: _loadDiscussions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _discussions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _DiscussionLinkCard(
          discussion: _discussions[i],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No linked discussions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discussions that reference this project will appear here.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DiscussionLinkCard extends StatelessWidget {
  final Discussion discussion;

  const _DiscussionLinkCard({required this.discussion});

  Color _stageColor(DiscussionStage stage) {
    switch (stage) {
      case DiscussionStage.problem:
        return Colors.red[400]!;
      case DiscussionStage.solution:
        return Colors.amber[700]!;
      case DiscussionStage.projectProposal:
        return Colors.blue[600]!;
      case DiscussionStage.projectLinked:
        return Colors.green[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(discussion.stage);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: stageColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    discussion.stage.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: stageColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo(discussion.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              discussion.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (discussion.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                discussion.content,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage:
                      discussion.authorAvatarUrl != null &&
                              discussion.authorAvatarUrl!.isNotEmpty
                          ? NetworkImage(discussion.authorAvatarUrl!)
                          : null,
                  backgroundColor: Colors.grey[200],
                  child: discussion.authorAvatarUrl == null ||
                          discussion.authorAvatarUrl!.isEmpty
                      ? Text(
                          discussion.authorName.isNotEmpty
                              ? discussion.authorName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(fontSize: 10),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  discussion.authorName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.chat_bubble_outline,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${discussion.repliesCount}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.thumb_up_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${discussion.likesCount}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
