import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/discussion_model.dart';
import '../../utils/time_ago.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../screens/community/discussion_detail_screen.dart';
import '../../screens/community/discussion_pipeline_panel.dart';
import '../../services/discussions_service.dart';
import '../../utils/error_handler.dart';
import 'delete_confirmation_dialog.dart';
import 'error_snackbar.dart';
import 'media_gallery_widget.dart';

// Dark palette
const _kCardBg        = Color(0xFF1C1C1E);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);
const _kInputFill     = Color(0xFF252528);

/// Dark-themed discussion feed card.
class DiscussionFeedCard extends StatelessWidget {
  final Discussion discussion;
  final VoidCallback? onLike;
  final VoidCallback? onDeleted;

  const DiscussionFeedCard({
    super.key,
    required this.discussion,
    this.onLike,
    this.onDeleted,
  });

  Color _categoryColor(String category) {
    switch (category) {
      case 'world_problems':      return const Color(0xFF057642);
      case 'ideas':               return const Color(0xFFF5A623);
      case 'learning':            return const Color(0xFF0A66C2);
      case 'live_events':         return const Color(0xFFCC1016);
      case 'networking':          return const Color(0xFF7B61FF);
      case 'feedback':            return const Color(0xFFE91E8C);
      default:                    return const Color(0xFF666666);
    }
  }

  static const int _trendingLikesThreshold   = 10;
  static const int _trendingRepliesThreshold = 5;

  bool get _isTrending =>
      discussion.likesCount >= _trendingLikesThreshold ||
      discussion.repliesCount >= _trendingRepliesThreshold;

  @override
  Widget build(BuildContext context) {
    final cat      = DiscussionCategory.fromValue(discussion.category);
    final catLabel = cat?.label ?? discussion.category;
    final catColor = _categoryColor(discussion.category);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAuthor = currentUserId == discussion.authorId;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DiscussionDetailScreen(discussionId: discussion.id),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: _kBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category accent strip ─────────────────────────────────
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor, catColor.withOpacity(0.4)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // ── Author row ──────────────────────────────────────────────
            _buildDarkCardHeader(context, isAuthor),

            const SizedBox(height: 10),

            // ── Badges row ──────────────────────────────────────────────
            Row(
              children: [
                _buildCategoryBadge(catLabel, catColor),
                if (_isTrending) ...[
                  const SizedBox(width: 8),
                  _buildTrendingBadge(),
                ],
                if (discussion.isPinned) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.push_pin_outlined,
                      size: 14, color: _kTextSecondary),
                ],
                if (discussion.stage != DiscussionStage.problem) ...[
                  const SizedBox(width: 8),
                  PipelineStageBadge(stage: discussion.stage),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // ── Title ────────────────────────────────────────────────────
            Text(
              discussion.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // ── Content preview ───────────────────────────────────────────
            Text(
              discussion.content,
              style: const TextStyle(
                fontSize: 13,
                color: _kTextSecondary,
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Tags ───────────────────────────────────────────────────────
            if (discussion.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: discussion.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                          color: catColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── Media gallery ─────────────────────────────────────────────
            if (discussion.hasMedia) ...[
              const SizedBox(height: 12),
              MediaGalleryWidget(media: discussion.media),
            ],

            const SizedBox(height: 14),

            // ── Engagement bar ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kInputFill,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  _DarkEngagementBtn(
                    icon: discussion.isLikedByUser
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: '${discussion.likesCount}',
                    color: discussion.isLikedByUser
                        ? AppColors.deepRed
                        : _kTextSecondary,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 2),
                  _DarkEngagementBtn(
                    icon: Icons.chat_bubble_outline,
                    label: '${discussion.repliesCount}',
                    color: _kTextSecondary,
                  ),
                  const SizedBox(width: 2),
                  _DarkEngagementBtn(
                    icon: Icons.visibility_outlined,
                    label: '${discussion.viewsCount}',
                    color: _kTextSecondary,
                  ),
                  if (discussion.votesCount != 0) ...[
                    const SizedBox(width: 2),
                    _DarkEngagementBtn(
                      icon: discussion.votesCount > 0
                          ? Icons.thumb_up_outlined
                          : Icons.thumb_down_outlined,
                      label: discussion.votesCount > 0
                          ? '+${discussion.votesCount}'
                          : '${discussion.votesCount}',
                      color: discussion.votesCount > 0
                          ? AppColors.forestGreen
                          : AppColors.deepRed,
                    ),
                  ],
                  const Spacer(),
                  _DarkEngagementBtn(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: _kTextSecondary,
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
);
  }

  Widget _buildDarkCardHeader(BuildContext context, bool isAuthor) {
    final initial = discussion.authorName.isNotEmpty
        ? discussion.authorName[0].toUpperCase()
        : '?';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.electricBlue.withOpacity(0.25),
          backgroundImage: discussion.authorAvatarUrl != null
              ? NetworkImage(discussion.authorAvatarUrl!)
              : null,
          onBackgroundImageError:
              discussion.authorAvatarUrl != null ? (_, __) {} : null,
          child: discussion.authorAvatarUrl == null
              ? Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brightCyan,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                discussion.authorName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                timeAgo(discussion.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: _kTextSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isAuthor)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz,
                size: 20, color: _kTextSecondary),
            color: const Color(0xFF2A2A2D),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            onSelected: (value) {
              if (value == 'delete') _handleDelete(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCategoryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTrendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
            color: AppColors.warmAmber.withOpacity(0.4), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: 11)),
          SizedBox(width: 3),
          Text(
            'Trending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warmAmber,
            ),
          ),
        ],
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
                borderRadius: BorderRadius.circular(8)),
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

class _DarkEngagementBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DarkEngagementBtn({
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
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
