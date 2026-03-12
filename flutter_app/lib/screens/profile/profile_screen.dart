import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../services/projects_service.dart';
import '../../models/user_model.dart';
import '../../models/project_model.dart';
import '../../main.dart';
import '../../widgets/video_player_dialog.dart';
import 'edit_profile_screen.dart';
import 'my_applications_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  UserProfile? _userProfile;
  List<Project> _userProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? 'User';
      final userEmail = prefs.getString('userEmail') ?? 'user@example.com';
      final userId = prefs.getString('userId') ?? '';

      UserProfile? profile;
      List<Project> projects = [];
      if (userId.isNotEmpty) {
        try {
          final results = await Future.wait([
            UserService.getProfile(userId),
            ProjectsService.getUserProjects(userId),
          ]);
          profile = results[0] as UserProfile;
          projects = results[1] as List<Project>;
        } catch (e) {
          debugPrint('Failed to load profile data: $e');
        }
      }

      setState(() {
        _userName = userName;
        _userEmail = userEmail;
        _userProfile = profile;
        _userProjects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        ErrorSnackbar.show(context, appError, onRetry: _loadUserData);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await UserService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleEditProfile() async {
    if (_userProfile == null) return;

    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _userProfile!),
      ),
    );

    if (updated != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', updated.name);
      setState(() {
        _userProfile = updated;
        _userName = updated.name;
      });
    }
  }

  int get _activeProjectsCount {
    return _userProjects.where((p) => p.status == 'open').length;
  }

  Color _getExpertiseColor(String expertise) {
    switch (expertise) {
      case 'Technical': return Colors.blue;
      case 'Business': return Colors.green;
      case 'Marketing': return Colors.orange;
      case 'Operations': return Colors.purple;
      case 'Creative': return Colors.pink;
      case 'Legal': return Colors.indigo;
      case 'Domain': return Colors.red;
      case 'Soft Skills': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  String _getExpertiseIcon(String expertise) {
    switch (expertise) {
      case 'Technical': return '💻';
      case 'Business': return '💼';
      case 'Marketing': return '📢';
      case 'Operations': return '⚙️';
      case 'Creative': return '🎨';
      case 'Legal': return '⚖️';
      case 'Domain': return '🎯';
      case 'Soft Skills': return '🤝';
      default: return '📌';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Hero header with cover & avatar
                  SliverToBoxAdapter(child: _buildHeroHeader(context)),

                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Stats row
                        _buildStats(),
                        const SizedBox(height: AppSpacing.xl),

                        // Action buttons
                        _buildActionButtons(context),
                        const SizedBox(height: AppSpacing.xl),

                        // Projects section
                        _buildProjectsSection(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    const coverHeight = 160.0;
    const avatarRadius = 44.0;
    const borderWidth = 4.0;
    const avatarTotalRadius = avatarRadius + borderWidth;
    const stackHeight = coverHeight + avatarTotalRadius + AppSpacing.lg;

    final displayName = _userProfile?.name ?? _userName;
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final avatarUrl = _userProfile?.avatarUrl;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover photo gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: coverHeight,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.white.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons (top-right in the cover)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                if (_userProfile != null)
                  _HeaderIconButton(
                    icon: Icons.edit_outlined,
                    onTap: _handleEditProfile,
                    tooltip: 'Edit Profile',
                  ),
                const SizedBox(width: AppSpacing.sm),
                _HeaderIconButton(
                  icon: Icons.logout,
                  onTap: _handleLogout,
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),

          // Avatar centered at the cover bottom edge
          Positioned(
            top: coverHeight - avatarTotalRadius,
            left: AppSpacing.xl,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey300.withAlpha(153),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.primary,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                onBackgroundImageError:
                    avatarUrl != null ? (_, __) {} : null,
                child: avatarUrl == null
                    ? Text(
                        initial,
                        style: AppTextStyles.heading2
                            .copyWith(color: AppColors.white),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Projects',
            _userProjects.length.toString(),
            Icons.folder_outlined,
            AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _buildStatCard(
            'Active Projects',
            _activeProjectsCount.toString(),
            Icons.folder_open,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200.withAlpha(153),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppSpacing.iconLg),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: AppColors.grey900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final displayName = _userProfile?.name ?? _userName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name & info
        Text(displayName, style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text(_userEmail,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey500)),

        if (_userProfile?.primaryExpertise != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: _getExpertiseColor(_userProfile!.primaryExpertise!),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '${_getExpertiseIcon(_userProfile!.primaryExpertise!)} ${_userProfile!.primaryExpertise!}',
              style: AppTextStyles.captionMedium
                  .copyWith(color: AppColors.white, fontSize: 13),
            ),
          ),
        ],

        if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _userProfile!.bio!,
            style: AppTextStyles.body2,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        if (_userProfile?.location != null &&
            _userProfile!.location!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.grey400),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _userProfile!.location!,
                style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // Buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyApplicationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Applications'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Projects', style: AppTextStyles.heading4),
        const SizedBox(height: AppSpacing.lg),

        if (_userProjects.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(Icons.folder_off_outlined,
                      size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('No projects yet', style: AppTextStyles.heading5),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Create your first project to get started!',
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.grey500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userProjects.length,
            itemBuilder: (context, index) {
              final project = _userProjects[index];
              return _buildProjectCard(project);
            },
          ),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    final isActive = project.status == 'open';
    final statusColor = isActive ? AppColors.success : AppColors.grey400;
    final statusText =
        isActive ? 'Active' : project.status.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200.withAlpha(153),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            if (project.videoUrl != null)
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => VideoPlayerDialog(
                    videoUrl: project.videoUrl!,
                    projectTitle: project.title,
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      project.thumbnailUrl != null
                          ? Image.network(
                              project.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.grey100,
                                child: const Icon(Icons.video_library,
                                    size: 48, color: AppColors.grey400),
                              ),
                            )
                          : Container(
                              color: AppColors.grey100,
                              child: const Icon(Icons.video_library,
                                  size: 48, color: AppColors.grey400),
                            ),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.white.withAlpha(217),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: AppColors.primary, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(project.title,
                            style: AppTextStyles.heading5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Text(
                          statusText,
                          style: AppTextStyles.captionMedium
                              .copyWith(color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    project.description,
                    style: AppTextStyles.body2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (project.requiredSkills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: project.requiredSkills.take(3).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                          ),
                          child: Text(
                            skill,
                            style: AppTextStyles.captionMedium
                                .copyWith(color: AppColors.primaryDark),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small icon button for use on the gradient header (white tinted background)
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: AppColors.white, size: AppSpacing.iconLg),
        ),
      ),
    );
  }
}
