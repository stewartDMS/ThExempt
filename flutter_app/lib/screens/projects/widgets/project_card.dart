import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/project_model.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 0, vertical: 0),
      decoration: const BoxDecoration(
        color: AppColors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
              // ── Header: avatar + name + time + bookmark ────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _buildHeader(context),
              ),

              // ── Video thumbnail ────────────────────────────────────────
              if (project.videoUrl != null)
                _buildVideoThumbnail(context),

              // ── Content ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + "New" badge
                    _buildTitle(),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      project.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey500,
                        height: 1.45,
                      ),
                    ),

                    // Skills
                    if (project.requiredSkills.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildSkillChips(),
                    ],

                    // Roles summary
                    if (project.totalRolesNeeded > 0) ...[
                      const SizedBox(height: 10),
                      _buildRolesSummary(),
                    ],

                    const SizedBox(height: 12),
                    // CTA row
                    _buildCTARow(context),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            project.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_isNew) ...[
          const SizedBox(width: AppSpacing.sm),
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
    );
  }

  Widget _buildSkillChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: project.requiredSkills
          .take(3)
          .map((skill) => SkillChip(label: skill))
          .toList(),
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
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ProjectDetailScreen(projectId: project.id),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            child: const Text(
              'View Project',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_outlined,
                color: AppColors.grey500, size: 20),
            padding: const EdgeInsets.all(9),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}
