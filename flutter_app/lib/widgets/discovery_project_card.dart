import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../utils/time_ago.dart';
import 'video_player_dialog.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/projects_service.dart';
import '../utils/error_handler.dart';
import 'common/delete_confirmation_dialog.dart';
import 'common/error_snackbar.dart';

// ── Dark surface palette (same as ProjectCard) ────────────────────────────────
const _kCardBg = Color(0xFF1C1C1E);
const _kCardSurface = Color(0xFF252528);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);
const _kDivider = Color(0xFF2C2C2F);

/// Discovery-feed project card.
///
/// Redesigned to match LinkedIn-style post cards:
///   1. Author header (avatar · name · time · stage badge)
///   2. Full-width 16:9 media section (video | image | gradient banner)
///   3. Title + description
///   4. Endorsements / contributors stats
///   5. Skill chips
///   6. Roles progress bar
///   7. CTA row (Contribute | View | Bookmark)
///
/// Optionally shows a match-percentage badge and a "Perfect match!" banner.
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isNew =>
      DateTime.now().difference(project.createdAt).inDays < 3;

  Color _matchColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  void _openProject(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProjectDetailScreen(projectId: project.id),
    ));
  }

  void _openProjectContribute(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProjectDetailScreen(
        projectId: project.id,
        initialTabIndex: ProjectDetailScreen.investTabIndex,
      ),
    ));
  }

  void _openOwnerProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UserProfileScreen(userId: project.ownerId),
    ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Project deleted successfully'),
          ]),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
        onDeleted?.call();
      }
    } catch (e) {
      if (context.mounted) {
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        ErrorSnackbar.show(context, appError);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = project.stage.color;
    final isPerfectMatch = matchScore != null && matchScore! >= 90;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openProject(context),
            splashColor: accent.withOpacity(0.08),
            highlightColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thin stage-colour accent strip ────────────────────────
                _AccentStrip(color: accent),

                // ── Perfect match banner ──────────────────────────────────
                if (isPerfectMatch)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: AppColors.forestGreen.withOpacity(0.15),
                    child: Row(
                      children: [
                        const Text('⭐',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        const Text(
                          'Perfect match for you!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
                  child: _buildHeader(context),
                ),

                // ── Media section: always visible ─────────────────────────
                _buildMediaSection(context),

                // ── Content ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + NEW badge
                      _buildTitleRow(),
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _kTextSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Stats row
                      _buildKeyStats(),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: _kDivider),
                      const SizedBox(height: 12),
                      // Skill chips
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
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final isOwner =
        currentUserId != null && currentUserId == project.ownerId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        GestureDetector(
          onTap: () => _openOwnerProfile(context),
          child: _buildAvatar(),
        ),
        const SizedBox(width: 10),
        // Name + time
        Expanded(
          child: GestureDetector(
            onTap: () => _openOwnerProfile(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.ownerName,
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
                  timeAgo(project.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: _kTextSecondary),
                ),
              ],
            ),
          ),
        ),
        // Stage badge
        _StagePill(stage: project.stage),
        const SizedBox(width: 6),
        // Menu / match score
        if (isOwner)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: _kTextSecondary, size: 20),
            color: _kCardSurface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            onSelected: (value) {
              if (value == 'delete') _handleDelete(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline,
                      size: 18, color: AppColors.deepRed),
                  const SizedBox(width: 10),
                  Text('Delete',
                      style: TextStyle(
                          color: AppColors.deepRed, fontSize: 14)),
                ]),
              ),
            ],
          )
        else if (matchScore != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _matchColor(matchScore!).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                  color: _matchColor(matchScore!).withOpacity(0.35)),
            ),
            child: Text(
              '$matchScore%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _matchColor(matchScore!),
              ),
            ),
          )
        else
          Icon(Icons.bookmark_border_outlined,
              color: _kTextSecondary, size: 20),
      ],
    );
  }

  Widget _buildAvatar() {
    if (project.ownerAvatarUrl != null &&
        project.ownerAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(project.ownerAvatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.electricBlue.withOpacity(0.2),
      child: Text(
        project.ownerName.isNotEmpty
            ? project.ownerName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.brightCyan,
        ),
      ),
    );
  }

  // ── Media section ─────────────────────────────────────────────────────────

  /// Always visible: video → first image → gradient banner.
  Widget _buildMediaSection(BuildContext context) {
    if (project.videoUrl != null) return _buildVideoThumbnail(context);
    final images =
        project.media.where((m) => m.isImage).toList();
    if (images.isNotEmpty) {
      return _buildImageBanner(context, images.first.fileUrl);
    }
    return _buildGradientBanner();
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
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),
            // Play button
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.electricBlue, size: 34),
              ),
            ),
            // Duration badge
            if (project.media.any((m) => m.isVideo && m.durationSeconds != null))
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(project.media
                        .firstWhere((m) => m.isVideo)
                        .durationSeconds!),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBanner(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _openProject(context),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientBanner(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.55, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBanner() {
    final accent = project.stage.color;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF14141A),
                  accent.withOpacity(0.30),
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            right: -28,
            top: -28,
            child: _Circle(size: 130, color: accent.withOpacity(0.18)),
          ),
          Positioned(
            right: 22,
            top: 18,
            child: _Circle(size: 55, color: accent.withOpacity(0.12)),
          ),
          Positioned(
            left: -18,
            bottom: -18,
            child: _Circle(
                size: 80,
                color: AppColors.electricBlue.withOpacity(0.14)),
          ),
          // Bottom scrim
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.45, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),
          // Title overlay
          Positioned(
            left: 16,
            right: 56,
            bottom: 14,
            child: Text(
              project.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Stage emoji badge
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: Text(
                project.stage.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2C),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined,
              size: 40, color: Color(0xFF555558)),
          SizedBox(height: 6),
          Text('Video pitch',
              style: TextStyle(
                  color: Color(0xFF666669), fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── Title row ─────────────────────────────────────────────────────────────

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            project.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_isNew) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.electricBlue, AppColors.brightCyan],
              ),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  // ── Key stats ─────────────────────────────────────────────────────────────

  Widget _buildKeyStats() {
    return Row(
      children: [
        _StatItem(
          icon: Icons.thumb_up_alt_outlined,
          value: '${project.endorsementsCount}',
          label: 'Endorsements',
          color: AppColors.electricBlue,
        ),
        const SizedBox(width: 16),
        _StatItem(
          icon: Icons.group_outlined,
          value: '${project.investorCount}',
          label: 'Contributors',
          color: AppColors.forestGreen,
        ),
        if (project.totalInvested > 0) ...[
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.monetization_on_outlined,
            value: _formatAmount(project.totalInvested),
            label: 'Funded',
            color: AppColors.warmAmber,
          ),
        ],
      ],
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }

  // ── Skills ────────────────────────────────────────────────────────────────

  Widget _buildSkillChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: project.requiredSkills
          .take(4)
          .map((skill) => _DarkSkillChip(label: skill))
          .toList(),
    );
  }

  // ── Roles progress ────────────────────────────────────────────────────────

  Widget _buildRolesProgress() {
    final filled = project.rolesFilled;
    final total = project.totalRolesNeeded;
    final progress = total > 0 ? filled / total : 0.0;
    final openRoles = total - filled;

    final Color progressColor;
    if (progress >= 0.7) {
      progressColor = AppColors.forestGreen;
    } else if (progress >= 0.3) {
      progressColor = AppColors.warmAmber;
    } else {
      progressColor = AppColors.deepRed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group_outlined,
                size: 13, color: _kTextSecondary),
            const SizedBox(width: 4),
            Text(
              '$filled/$total roles filled',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kTextSecondary),
            ),
            const Spacer(),
            if (openRoles > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '$openRoles open',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  // ── CTA row ───────────────────────────────────────────────────────────────

  Widget _buildCTARow(BuildContext context) {
    return Row(
      children: [
        // Primary: gradient Contribute button
        Expanded(
          flex: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.electricBlue, AppColors.brightCyan],
              ),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _openProjectContribute(context),
              icon: const Icon(Icons.volunteer_activism, size: 15),
              label: const Text('Contribute'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 11),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Secondary: ghost View button
        Expanded(
          flex: 3,
          child: OutlinedButton(
            onPressed: () => _openProject(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              side: BorderSide(
                  color: AppColors.brightCyan.withOpacity(0.4),
                  width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            child: const Text(
              'View',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brightCyan),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Bookmark
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_outlined,
                color: _kTextSecondary, size: 18),
            tooltip: 'Save project',
            padding: const EdgeInsets.all(9),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _AccentStrip extends StatelessWidget {
  final Color color;
  const _AccentStrip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final dynamic stage; // ProjectStage
  const _StagePill({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: (stage.color as Color).withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
            color: (stage.color as Color).withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stage.emoji as String,
              style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            stage.displayName as String,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: stage.color as Color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: _kTextSecondary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DarkSkillChip extends StatelessWidget {
  final String label;
  const _DarkSkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
            color: AppColors.electricBlue.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.brightCyan),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
