import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/project_model.dart';
import '../../../models/project_health.dart';
import '../../../utils/time_ago.dart';
import '../project_detail_screen.dart';
import '../../../widgets/video_player_dialog.dart';
import '../../profile/user_profile_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../services/projects_service.dart';
import '../../../utils/error_handler.dart';
import '../../../widgets/common/delete_confirmation_dialog.dart';
import '../../../widgets/common/error_snackbar.dart';
import '../../../widgets/common/stage_badge.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/premium_card.dart';
import '../../../widgets/common/premium_skill_chip.dart';
import '../../../widgets/common/media_gallery_widget.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  /// Called after the project has been successfully deleted.
  final VoidCallback? onDeleted;

  const ProjectCard({
    super.key,
    required this.project,
    this.onDeleted,
  });

  void _playVideo(BuildContext context) {
    if (project.videoUrl != null) {
      showDialog(
        context: context,
        builder: (context) => VideoPlayerDialog(
          videoUrl: project.videoUrl!,
          projectTitle: project.title,
        ),
      );
    }
  }

  void _openOwnerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: project.ownerId),
      ),
    );
  }

  bool get _isNew {
    return DateTime.now().difference(project.createdAt).inDays < 3;
  }

  @override
  Widget build(BuildContext context) {
    final health = ProjectHealth.calculate(project);
    return PremiumCard(
      accentColor: project.stage.color,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name + time + badge ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: _buildHeader(context),
          ),

          // ── Video thumbnail ────────────────────────────────────────────
          if (project.videoUrl != null)
            _buildVideoThumbnail(context),

          // ── Media gallery (images / extra videos) ─────────────────────
          if (project.hasMedia)
            MediaGalleryWidget(media: project.media),

          // ── Content ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + "New" badge + health chip
                _buildTitleRow(health),
                const SizedBox(height: 8),

                // Problem / Impact snippet (if available)
                if (project.hasProblemStatement) ...[
                  _buildProblemSnippet(),
                  const SizedBox(height: 8),
                ],

                // Description
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                    height: 1.5,
                  ),
                ),

                // Key stats: endorsements, investors, funding
                const SizedBox(height: 12),
                _buildKeyStats(),

                // Divider
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),

                // Skills
                if (project.requiredSkills.isNotEmpty) ...[
                  _buildSkillChips(),
                  const SizedBox(height: 12),
                ],

                // Roles progress
                if (project.totalRolesNeeded > 0) ...[
                  _buildRolesProgress(),
                  const SizedBox(height: 14),
                ],

                // CTA row
                _buildCTARow(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    return GestureDetector(
      onTap: () => _playVideo(context),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            project.thumbnailUrl != null
                ? Image.network(
                    project.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _videoPlaceholder(),
                  )
                : _videoPlaceholder(),
            // Bottom gradient overlay for readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(100),
                    ],
                  ),
                ),
              ),
            ),
            // Play button – centered, large, professional
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(230),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: AppColors.grey100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 44, color: AppColors.grey400),
          SizedBox(height: 8),
          Text('Video pitch',
              style: TextStyle(color: AppColors.grey400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == project.ownerId;

    return CardHeader(
      avatarUrl: project.ownerAvatarUrl,
      name: project.ownerName,
      subtitle: timeAgo(project.createdAt),
      onAvatarTap: () => _openOwnerProfile(context),
      onNameTap: () => _openOwnerProfile(context),
      badge: StageBadge(stage: project.stage, compact: true),
      trailing: isOwner
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.grey400),
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
                          size: 20, color: AppColors.error),
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
          : Icon(Icons.bookmark_border_outlined,
              color: AppColors.grey400, size: AppSpacing.iconLg),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Project?',
      message:
          'This action cannot be undone. The project and all its data will be permanently deleted.',
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await DeleteConfirmationDialog.withLoadingOverlay(
        context,
        () => ProjectsService.deleteProject(project.id),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Project deleted successfully'),
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

  Widget _buildTitleRow(ProjectHealth health) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            project.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildHealthChip(health),
            if (_isNew) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHealthChip(ProjectHealth health) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: health.scoreColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: health.scoreColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 11, color: health.scoreColor),
          const SizedBox(width: 3),
          Text(
            health.scoreLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: health.scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemSnippet() {
    final statement = project.problemStatement ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 14, color: AppColors.error.withOpacity(0.8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              statement,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error.withOpacity(0.85),
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStats() {
    return Row(
      children: [
        _buildStatBadge(
          Icons.thumb_up_alt_outlined,
          '${project.endorsementsCount}',
          'Endorsements',
          AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatBadge(
          Icons.group_outlined,
          '${project.investorCount}',
          'Contributors',
          AppColors.success,
        ),
        if (project.totalInvested > 0) ...[
          const SizedBox(width: 12),
          _buildStatBadge(
            Icons.monetization_on_outlined,
            _formatAmount(project.totalInvested),
            'Funded',
            AppColors.warning,
          ),
        ],
      ],
    );
  }

  Widget _buildStatBadge(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                  height: 1.2,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grey500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }

  Widget _buildSkillChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: project.requiredSkills
          .take(4)
          .map((skill) => PremiumSkillChip(
                label: skill,
                color: AppColors.primary,
              ))
          .toList(),
    );
  }

  Widget _buildRolesProgress() {
    final filled = project.rolesFilled;
    final total = project.totalRolesNeeded;
    final progress = total > 0 ? filled / total : 0.0;
    final openRoles = total - filled;

    final Color progressColor;
    if (progress >= 0.7) {
      progressColor = AppColors.success;
    } else if (progress >= 0.3) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group_outlined, size: 14, color: AppColors.grey500),
            const SizedBox(width: 4),
            Text(
              '$filled/$total roles filled',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.grey500,
              ),
            ),
            const Spacer(),
            if (openRoles > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '$openRoles open',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.grey100,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildRolesSummary() {
    final openRoles = project.totalRolesNeeded - project.rolesFilled;
    return Row(
      children: [
        const Icon(Icons.group_outlined,
            size: 15, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          '${project.rolesFilled}/${project.totalRolesNeeded} roles filled',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        if (openRoles > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$openRoles open',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCTARow(BuildContext context) {
    return Row(
      children: [
        // Primary: Contribute → opens Invest tab
        Expanded(
          flex: 5,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(
                  projectId: project.id,
                  initialTabIndex: ProjectDetailScreen.investTabIndex,
                ),
              ),
            ),
            icon: const Icon(Icons.volunteer_activism, size: 16),
            label: const Text('Contribute'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Secondary: Learn More → opens Overview
        Expanded(
          flex: 4,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ProjectDetailScreen(projectId: project.id),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            child: const Text(
              'Learn More',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Bookmark
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_outlined,
                color: AppColors.grey500, size: 20),
            tooltip: 'Save project',
            padding: const EdgeInsets.all(9),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}
