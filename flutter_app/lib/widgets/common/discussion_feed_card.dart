import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/discussion_model.dart';
import '../../utils/time_ago.dart';
import '../../theme/app_colors.dart';
import '../../screens/community/discussion_detail_screen.dart';
import '../../services/discussions_service.dart';
import '../../utils/error_handler.dart';
import 'delete_confirmation_dialog.dart';
import 'error_snackbar.dart';
import 'app_card.dart';

/// LinkedIn-style discussion feed card.
/// Shows author avatar, name, time, category badge, title, preview, and
/// an engagement bar (replies, likes, share).
class DiscussionFeedCard extends StatelessWidget {
  final Discussion discussion;
  final VoidCallback? onLike;

  /// Called after the discussion has been successfully deleted.
  final VoidCallback? onDeleted;

  const DiscussionFeedCard({
    super.key,
    required this.discussion,
    this.onLike,
    this.onDeleted,
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

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAuthor = currentUserId == discussion.authorId;

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
            CardHeader(
              avatarUrl: discussion.authorAvatarUrl,
              name: discussion.authorName,
              subtitle: timeAgo(discussion.createdAt),
              trailing: isAuthor
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          size: 20, color: AppColors.grey500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _handleDelete(context);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.error),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : discussion.isPinned
                      ? const Padding(
                          padding: EdgeInsets.only(left: 6, top: 2),
                          child: Icon(Icons.push_pin_outlined,
                              size: 16, color: AppColors.grey500),
                        )
                      : null,
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
                  return SkillChip(
                    label: '#$tag',
                    color: AppColors.grey500,
                    backgroundColor: AppColors.grey100,
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

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Discussion?',
      message:
          'This will permanently delete this discussion and all its replies.',
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await DeleteConfirmationDialog.withLoadingOverlay(
        context,
        () => DiscussionsService.deleteDiscussion(discussion.id),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Discussion deleted'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        onDeleted?.call();
      }
    } catch (e) {
      if (context.mounted) {
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        ErrorSnackbar.show(context, appError);
      }
    }
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
