import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../utils/time_ago.dart';
import '../../theme/app_colors.dart';
import '../../screens/community/discussion_detail_screen.dart';

/// LinkedIn-style discussion feed card.
/// Shows author avatar, name, time, category badge, title, preview, and
/// an engagement bar (replies, likes, share).
class DiscussionFeedCard extends StatelessWidget {
  final Discussion discussion;
  final VoidCallback? onLike;

  const DiscussionFeedCard({
    super.key,
    required this.discussion,
    this.onLike,
  });

  Color _categoryColor(String category) {
    switch (category) {
      case 'world_problems':
        return const Color(0xFF057642);
      case 'ideas':
        return const Color(0xFFF5A623);
      case 'learning':
        return const Color(0xFF0A66C2);
      case 'live_events':
        return const Color(0xFFCC1016);
      case 'networking':
        return const Color(0xFF7B61FF);
      case 'feedback':
        return const Color(0xFFE91E8C);
      default:
        return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = DiscussionCategory.fromValue(discussion.category);
    final catLabel = cat?.label ?? discussion.category;
    final catColor = _categoryColor(discussion.category);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DiscussionDetailScreen(discussionId: discussion.id),
        ));
      },
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author row ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                _buildAvatar(),
                const SizedBox(width: 10),
                // Name + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discussion.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        timeAgo(discussion.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (discussion.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(left: 6, top: 2),
                    child: Icon(Icons.push_pin_outlined,
                        size: 16, color: AppColors.grey500),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Category badge ────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: catColor.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: catColor.withAlpha(60)),
              ),
              child: Text(
                catLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: catColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              discussion.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // ── Content preview ───────────────────────────────────────────
            Text(
              discussion.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Tags ──────────────────────────────────────────────────────
            if (discussion.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: discussion.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey500),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // ── Engagement bar ────────────────────────────────────────────
            Row(
              children: [
                _EngagementBtn(
                  icon: discussion.isLikedByUser
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: '${discussion.likesCount}',
                  color: discussion.isLikedByUser
                      ? const Color(0xFFCC1016)
                      : AppColors.grey500,
                  onTap: onLike,
                ),
                const SizedBox(width: 4),
                _EngagementBtn(
                  icon: Icons.chat_bubble_outline,
                  label: '${discussion.repliesCount}',
                  color: AppColors.grey500,
                ),
                const SizedBox(width: 4),
                _EngagementBtn(
                  icon: Icons.visibility_outlined,
                  label: '${discussion.viewsCount}',
                  color: AppColors.grey500,
                ),
                const Spacer(),
                _EngagementBtn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppColors.grey500,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (discussion.authorAvatarUrl != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(discussion.authorAvatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryContainer,
      child: Text(
        discussion.authorName.isNotEmpty
            ? discussion.authorName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EngagementBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _EngagementBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
