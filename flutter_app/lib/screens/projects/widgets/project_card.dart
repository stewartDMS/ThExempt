import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../utils/time_ago.dart';
import '../project_detail_screen.dart';
import '../../../widgets/video_player_dialog.dart';
import '../../profile/user_profile_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/text_styles.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({
    super.key,
    required this.project,
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
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withAlpha(102),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                // Video thumbnail
                if (project.videoUrl != null)
                  _buildVideoThumbnail(context),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: avatar + name + time + bookmark
                      _buildHeader(context),
                      const SizedBox(height: AppSpacing.md),

                      // Title + "New" badge
                      _buildTitle(),
                      const SizedBox(height: AppSpacing.sm),

                      // Description
                      Text(
                        project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2.copyWith(height: 1.5),
                      ),

                      // Skills
                      if (project.requiredSkills.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildSkillChips(),
                      ],

                      // Roles summary
                      if (project.totalRolesNeeded > 0) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildRolesSummary(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
            // Gradient overlay for play button visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(77),
                  ],
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
                      color: Colors.black.withAlpha(51),
                      blurRadius: 12,
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
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: AppColors.grey100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 48, color: AppColors.grey400),
          SizedBox(height: AppSpacing.sm),
          Text('Video pitch', style: TextStyle(color: AppColors.grey400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _openOwnerProfile(context),
          child: project.ownerAvatarUrl != null
              ? CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(project.ownerAvatarUrl!),
                  onBackgroundImageError: (_, __) {},
                )
              : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      project.ownerName.isNotEmpty
                          ? project.ownerName[0].toUpperCase()
                          : 'U',
                      style: AppTextStyles.heading5
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openOwnerProfile(context),
                child: Text(
                  project.ownerName,
                  style: AppTextStyles.heading6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeAgo(project.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Icon(Icons.bookmark_border, color: AppColors.grey300, size: AppSpacing.iconLg),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            project.title,
            style: AppTextStyles.heading4,
          ),
        ),
        if (_isNew) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 3),
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: project.requiredSkills.take(3).map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            skill,
            style: AppTextStyles.captionMedium
                .copyWith(color: AppColors.primaryDark),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRolesSummary() {
    final openRoles = project.totalRolesNeeded - project.rolesFilled;
    return Row(
      children: [
        const Icon(Icons.group_outlined,
            size: AppSpacing.iconSm + 2, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${project.rolesFilled}/${project.totalRolesNeeded} roles filled',
          style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary),
        ),
        if (openRoles > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$openRoles open',
              style: AppTextStyles.captionMedium
                  .copyWith(color: AppColors.success),
            ),
          ),
        ],
      ],
    );
  }
}
