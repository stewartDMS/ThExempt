import 'package:flutter/material.dart';
import '../models/discussion_model.dart';
import '../utils/time_ago.dart';
import '../screens/community/discussion_detail_screen.dart';

class DiscussionCard extends StatelessWidget {
  final Discussion discussion;
  final VoidCallback? onLike;

  const DiscussionCard({
    super.key,
    required this.discussion,
    this.onLike,
  });

  Color _categoryColor(String category) {
    switch (category) {
      case 'world_problems': return const Color(0xFF10B981);
      case 'ideas': return const Color(0xFFF59E0B);
      case 'learning': return const Color(0xFF3B82F6);
      case 'live_events': return const Color(0xFFEF4444);
      case 'networking': return const Color(0xFF8B5CF6);
      case 'feedback': return const Color(0xFFEC4899);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = DiscussionCategory.fromValue(discussion.category);
    final catLabel = cat?.label ?? discussion.category;
    final catColor = _categoryColor(discussion.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DiscussionDetailScreen(discussionId: discussion.id),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: catColor.withAlpha(80)),
                    ),
                    child: Text(catLabel,
                        style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (discussion.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.push_pin, size: 14, color: Colors.orange),
                    ),
                  Text(timeAgo(discussion.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                discussion.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Content preview
              Text(
                discussion.content,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Tags
              if (discussion.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: discussion.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('#$tag', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 10),
              // Footer row: author + stats
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: discussion.authorAvatarUrl != null
                        ? NetworkImage(discussion.authorAvatarUrl!)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                    child: discussion.authorAvatarUrl == null
                        ? Text(discussion.authorName.isNotEmpty ? discussion.authorName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(discussion.authorName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  _StatChip(icon: Icons.favorite_outline, count: discussion.likesCount,
                      active: discussion.isLikedByUser, onTap: onLike),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.chat_bubble_outline, count: discussion.repliesCount),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.visibility_outlined, count: discussion.viewsCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  const _StatChip({required this.icon, required this.count, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14,
              color: active ? Theme.of(context).colorScheme.primary : Colors.grey[500]),
          const SizedBox(width: 2),
          Text('$count', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
