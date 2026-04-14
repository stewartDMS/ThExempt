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
import '../wallet/wallet_screen.dart';
import '../membership/membership_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/skeleton_project_card.dart';
import '../../widgets/common/shimmer_widget.dart';
import '../projects/project_detail_screen.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kDivider       = Color(0xFF2C2C2F);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName  = '';
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
      final prefs    = await SharedPreferences.getInstance();
      final userName  = prefs.getString('userName')  ?? 'User';
      final userEmail = prefs.getString('userEmail') ?? 'user@example.com';
      final userId    = prefs.getString('userId')    ?? '';

      UserProfile? profile;
      List<Project> projects = [];
      if (userId.isNotEmpty) {
        try {
          final results = await Future.wait([
            UserService.getProfile(userId),
            ProjectsService.getUserProjects(userId),
          ]);
          profile  = results[0] as UserProfile;
          projects = results[1] as List<Project>;
        } catch (e) {
          debugPrint('Failed to load profile data: $e');
        }
      }
      setState(() {
        _userName     = userName;
        _userEmail    = userEmail;
        _userProfile  = profile;
        _userProjects = projects;
        _isLoading    = false;
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
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        title: const Text('Logout',
            style: TextStyle(color: _kTextPrimary)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: _kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.deepRed),
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
        _userName    = updated.name;
      });
    }
  }

  int get _activeProjectsCount =>
      _userProjects.where((p) => p.status == 'open').length;

  Color _getExpertiseColor(String expertise) {
    switch (expertise) {
      case 'Technical':   return AppColors.electricBlue;
      case 'Business':    return AppColors.forestGreen;
      case 'Marketing':   return AppColors.rebellionOrange;
      case 'Operations':  return AppColors.steelGray;
      case 'Creative':    return const Color(0xFFE91E8C);
      case 'Legal':       return const Color(0xFF7B61FF);
      case 'Domain':      return AppColors.deepRed;
      case 'Soft Skills': return AppColors.brightCyan;
      default:            return AppColors.grey500;
    }
  }

  String _getExpertiseIcon(String expertise) {
    switch (expertise) {
      case 'Technical':   return '💻';
      case 'Business':    return '💼';
      case 'Marketing':   return '📢';
      case 'Operations':  return '⚙️';
      case 'Creative':    return '🎨';
      case 'Legal':       return '⚖️';
      case 'Domain':      return '🎯';
      case 'Soft Skills': return '🤝';
      default:            return '📌';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _isLoading
          ? _buildSkeleton()
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: AppColors.brightCyan,
              backgroundColor: _kCardBg,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.bottomNavPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStats(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildUserInfo(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildActionGrid(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildProjectsSection(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Sliver App Bar / hero header ──────────────────────────────────────────

  Widget _buildSliverAppBar() {
    const coverHeight = 160.0;
    const avatarRadius = 44.0;
    const borderWidth = 3.0;
    const avatarTotalRadius = avatarRadius + borderWidth;

    final displayName = _userProfile?.name ?? _userName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final avatarUrl = _userProfile?.avatarUrl;

    return SliverAppBar(
      expandedHeight: coverHeight + avatarTotalRadius + 8,
      pinned: true,
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        if (_userProfile != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: _kTextSecondary, size: 22),
            tooltip: 'Edit Profile',
            onPressed: _handleEditProfile,
          ),
        IconButton(
          icon: const Icon(Icons.logout, color: _kTextSecondary, size: 22),
          tooltip: 'Logout',
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover gradient
            Positioned(
              top: 0, left: 0, right: 0,
              height: coverHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0D1B2A),
                      AppColors.electricBlue.withOpacity(0.45),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30, right: -20,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20, left: 30,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Avatar
            Positioned(
              top: coverHeight - avatarTotalRadius,
              left: AppSpacing.xl,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBg, width: borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: AppColors.electricBlue.withOpacity(0.4),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  onBackgroundImageError:
                      avatarUrl != null ? (_, __) {} : null,
                  child: avatarUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget(width: double.infinity, height: 200),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                ShimmerWidget(
                    width: 160,
                    height: 20,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
                const SizedBox(height: AppSpacing.sm),
                ShimmerWidget(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                        child: ShimmerWidget(
                            width: double.infinity,
                            height: 72,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                        child: ShimmerWidget(
                            width: double.infinity,
                            height: 72,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd))),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                ShimmerWidget(
                    width: double.infinity,
                    height: 48,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                const SizedBox(height: AppSpacing.xl),
                ShimmerWidget(
                    width: 120,
                    height: 18,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
                const SizedBox(height: AppSpacing.md),
                const SkeletonProjectCard(),
                const SkeletonProjectCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _DarkStatCard(
            label: 'Total Projects',
            value: _userProjects.length.toString(),
            icon: Icons.folder_outlined,
            color: AppColors.electricBlue,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _DarkStatCard(
            label: 'Active',
            value: _activeProjectsCount.toString(),
            icon: Icons.folder_open,
            color: AppColors.forestGreen,
          ),
        ),
      ],
    );
  }

  // ── User info + bio ────────────────────────────────────────────────────────

  Widget _buildUserInfo() {
    final displayName = _userProfile?.name ?? _userName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _userEmail,
          style: const TextStyle(fontSize: 13, color: _kTextSecondary),
        ),

        if (_userProfile?.primaryExpertise != null) ...[
          const SizedBox(height: 10),
          _ExpertisePill(
            label:
                '${_getExpertiseIcon(_userProfile!.primaryExpertise!)} ${_userProfile!.primaryExpertise!}',
            color: _getExpertiseColor(_userProfile!.primaryExpertise!),
          ),
        ],

        if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _userProfile!.bio!,
            style: const TextStyle(
                fontSize: 14, color: _kTextSecondary, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        if (_userProfile?.location != null &&
            _userProfile!.location!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: _kTextSecondary),
              const SizedBox(width: 4),
              Text(
                _userProfile!.location!,
                style: const TextStyle(
                    fontSize: 13, color: _kTextSecondary),
              ),
            ],
          ),
        ],

        if (_userProfile?.skills != null &&
            _userProfile!.skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _userProfile!.skills.take(5).map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                      color: AppColors.electricBlue.withOpacity(0.3)),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.brightCyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Action grid ───────────────────────────────────────────────────────────

  Widget _buildActionGrid() {
    final actions = [
      _ProfileAction(
        icon: Icons.description_outlined,
        label: 'Applications',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
        ),
      ),
      _ProfileAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Wallet',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WalletScreen()),
        ),
      ),
      _ProfileAction(
        icon: Icons.star_outline,
        label: 'Membership',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MembershipScreen()),
        ),
      ),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ActionButton(action: a),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Projects section ───────────────────────────────────────────────────────

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: 'My Projects',
          count: _userProjects.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_userProjects.isEmpty)
          _DarkEmptyState(
            icon: Icons.folder_off_outlined,
            title: 'No projects yet',
            subtitle: 'Create your first project to get started!',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userProjects.length,
            itemBuilder: (context, index) =>
                _DarkProjectCard(project: _userProjects[index]),
          ),
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _DarkStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DarkStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppSpacing.iconLg),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: _kTextSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExpertisePill extends StatelessWidget {
  final String label;
  final Color color;

  const _ExpertisePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

class _ProfileAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileAction(
      {required this.icon, required this.label, required this.onTap});
}

class _ActionButton extends StatelessWidget {
  final _ProfileAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            Icon(action.icon,
                color: AppColors.brightCyan, size: 22),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionHeader({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count != null ? '$label ($count)' : label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _DarkEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DarkEmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(icon, size: 32, color: AppColors.brightCyan),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13, color: _kTextSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DarkProjectCard extends StatelessWidget {
  final Project project;

  const _DarkProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final isActive    = project.status == 'open';
    final statusColor = isActive ? AppColors.forestGreen : AppColors.grey500;
    final statusText  = isActive ? 'Active' : project.status.toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(projectId: project.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: _kBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent strip (status colour)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusLg),
                      bottomLeft: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
                // Card body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Optional video thumbnail
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
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          color: const Color(0xFF252528),
                                          child: const Icon(
                                              Icons.video_library,
                                              size: 48,
                                              color: _kTextSecondary),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFF252528),
                                        child: const Icon(
                                            Icons.video_library,
                                            size: 48,
                                            color: _kTextSecondary),
                                      ),
                                Center(
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row + status badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    project.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _kTextPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull),
                                    border: Border.all(
                                        color:
                                            statusColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            // Description
                            Text(
                              project.description,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: _kTextSecondary,
                                  height: 1.45),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Skills
                            if (project.requiredSkills.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: project.requiredSkills
                                    .take(3)
                                    .map((skill) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.electricBlue
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppSpacing.radiusFull),
                                            border: Border.all(
                                                color: AppColors.electricBlue
                                                    .withOpacity(0.25)),
                                          ),
                                          child: Text(
                                            skill,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.brightCyan,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                            // Tap hint
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Spacer(),
                                const Text(
                                  'View details',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.brightCyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: AppColors.brightCyan,
                                ),
                              ],
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
      ),
    );
  }
}
