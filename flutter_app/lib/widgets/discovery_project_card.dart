import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../utils/time_ago.dart';
import 'team_composition_indicator.dart';
import 'video_player_dialog.dart';
import '../theme/app_colors.dart';
import '../services/projects_service.dart';
import '../utils/error_handler.dart';
import 'common/delete_confirmation_dialog.dart';
import 'common/error_snackbar.dart';
import 'common/stage_badge.dart';

/// Enhanced project card for the discovery screen.
/// Optionally displays a match percentage badge, open-role chips, a team
/// composition indicator, and a "Perfect match!" banner for ≥90 % matches.
class DiscoveryProjectCard extends StatelessWidget {
  final Project project;

  /// 0–100 match score (null = not calculated / user not logged in).
  final int? matchScore;

  /// Open role titles to preview on the card (max 3 shown).
  final List<String> openRoleTitles;

  /// Called after the project has been successfully deleted.
  final VoidCallback? onDeleted;

  const DiscoveryProjectCard({
    super.key,
    required this.project,
    this.matchScore,
    this.openRoleTitles = const [],
    this.onDeleted,
  });

  Color _matchColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  void _openProject(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: project.id),
      ),
    );
  }

  void _openOwnerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: project.ownerId),
      ),
    );
  }

  void _playVideo(BuildContext context) {
    if (project.videoUrl != null) {
      showDialog(
        context: context,
        builder: (_) => VideoPlayerDialog(
          videoUrl: project.videoUrl!,
          projectTitle: project.title,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final isPerfectMatch = matchScore != null && matchScore! >= 90;
    final openCount = project.totalRolesNeeded - project.rolesFilled;

    return Container(
      color: AppColors.white,
      child: InkWell(
        onTap: () => _openProject(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perfect-match banner
            if (isPerfectMatch)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                color: AppColors.successLight,
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Perfect match for you!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _openOwnerProfile(context),
                    child: project.ownerAvatarUrl != null
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                NetworkImage(project.ownerAvatarUrl!),
                            onBackgroundImageError: (_, __) {},
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              project.ownerName.isNotEmpty
                                  ? project.ownerName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _openOwnerProfile(context),
                          child: Text(
                            project.ownerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          timeAgo(project.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stage badge + Match badge or three-dot menu for owner
                  StageBadge(stage: project.stage, compact: true),
                  const SizedBox(width: 8),
                  if (Supabase.instance.client.auth.currentUser?.id ==
                      project.ownerId)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.grey400),
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
                  else if (matchScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _matchColor(matchScore!).withAlpha(20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _matchColor(matchScore!).withAlpha(80),
                        ),
                      ),
                      child: Text(
                        '$matchScore% match',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _matchColor(matchScore!),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video thumbnail
            if (project.videoUrl != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
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
                              errorBuilder: (_, __, ___) =>
                                  _videoPlaceholder(),
                            )
                          : _videoPlaceholder(),
                      // Bottom gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.5, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(90),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Play button
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
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
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
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
                  const SizedBox(height: 12),

                  // Skills chips
                  if (project.requiredSkills.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: project.requiredSkills.take(3).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Team composition indicator
                  TeamCompositionIndicator(
                    totalRoles: project.totalRolesNeeded,
                    filledRoles: project.rolesFilled,
                  ),

                  // Open roles preview
                  if (openRoleTitles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildOpenRolesPreview(openCount),
                  ] else if (openCount > 0) ...[
                    const SizedBox(height: 10),
                    _buildOpenRolesSummary(openCount),
                  ],
                ],
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
          Icon(Icons.video_library_outlined,
              size: 44, color: AppColors.grey400),
          SizedBox(height: 8),
          Text('Video pitch',
              style: TextStyle(color: AppColors.grey400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOpenRolesPreview(int openCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.work_outline, size: 13, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              '$openCount open role${openCount == 1 ? '' : 's'}:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: openRoleTitles.take(3).map((title) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.success.withAlpha(60)),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOpenRolesSummary(int openCount) {
    return Row(
      children: [
        const Icon(Icons.group_outlined, size: 13, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          '$openCount open role${openCount == 1 ? '' : 's'} available',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
