import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/discussion_model.dart';
import '../../utils/time_ago.dart';
import '../../theme/app_colors.dart';
import '../../screens/community/discussion_detail_screen.dart';
import '../../screens/community/media_viewer_screen.dart';
import '../../services/discussions_service.dart';
import '../../utils/error_handler.dart';
import 'delete_confirmation_dialog.dart';
import 'error_snackbar.dart';
import 'app_card.dart';
import 'premium_card.dart';
import 'premium_skill_chip.dart';

/// Premium discussion feed card.
/// Shows author avatar, name, time, category badge, title, preview,
/// tags, engagement metrics, and trending indicator.
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

  static const int _trendingLikesThreshold = 10;
  static const int _trendingRepliesThreshold = 5;

  bool get _isTrending =>
      discussion.likesCount >= _trendingLikesThreshold ||
      discussion.repliesCount >= _trendingRepliesThreshold;

  @override
  Widget build(BuildContext context) {
    final cat = DiscussionCategory.fromValue(discussion.category);
    final catLabel = cat?.label ?? discussion.category;
    final catColor = _categoryColor(discussion.category);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAuthor = currentUserId == discussion.authorId;

    return PremiumCard(
      accentColor: catColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              DiscussionDetailScreen(discussionId: discussion.id),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author row ────────────────────────────────────────────────
            CardHeader(
              avatarUrl: discussion.authorAvatarUrl,
              name: discussion.authorName,
              subtitle: timeAgo(discussion.createdAt),
              trailing: _buildTrailing(context, isAuthor),
            ),

            const SizedBox(height: 12),

            // ── Category badge + trending ─────────────────────────────────
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
                      size: 14, color: AppColors.grey500),
                ],
              ],
            ),

            const SizedBox(height: 10),

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

            const SizedBox(height: 6),

            // ── Content preview ───────────────────────────────────────────
            Text(
              discussion.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Tags ──────────────────────────────────────────────────────
            if (discussion.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: discussion.tags.take(3).map((tag) {
                  return PremiumSkillChip(
                    label: '#$tag',
                    color: catColor,
                  );
                }).toList(),
              ),
            ],

            // ── Media gallery ─────────────────────────────────────────────
            if (discussion.hasMedia) ...[
              const SizedBox(height: 12),
              _buildMediaGallery(context),
            ],

            const SizedBox(height: 14),

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

  Widget _buildMediaGallery(BuildContext context) {
    final media = discussion.media;
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        itemBuilder: (context, index) {
          final item = media[index];
          return Padding(
            padding: EdgeInsets.only(right: index < media.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                if (item.isImage) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MediaViewerScreen(
                      mediaFiles: media,
                      initialIndex: index,
                    ),
                  ));
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.isImage
                    ? Image.network(
                        item.fileUrl,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 160,
                          height: 160,
                          color: AppColors.grey200,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppColors.grey500),
                        ),
                      )
                    : Stack(
                        children: [
                          item.thumbnailUrl != null
                              ? Image.network(
                                  item.thumbnailUrl!,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 160,
                                    height: 160,
                                    color: Colors.black87,
                                  ),
                                )
                              : Container(
                                  width: 160,
                                  height: 160,
                                  color: Colors.black87,
                                ),
                          const Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, bool isAuthor) {
    if (isAuthor) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.grey500),
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
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCategoryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
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
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB800).withOpacity(0.4),
          width: 1,
        ),
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
              color: Color(0xFF8B6900),
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
