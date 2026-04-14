import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/project_model.dart';
import '../../services/user_service.dart';
import '../../services/projects_service.dart';
import '../../services/changemakers_service.dart';
import '../../services/collaboration_service.dart';
import '../../models/collaboration_request_model.dart';
import '../../screens/projects/project_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_snackbar.dart';

const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kDivider       = Color(0xFF2C2C2F);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserProfile? _user;
  List<Project> _projects = [];
  Map<String, int> _stats = {};
  Map<String, dynamic> _impactStats = {};
  bool _isLoading = true;
  bool _sendingRequest = false;
  CollabRequestStatus? _requestStatus;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        UserService.getProfile(widget.userId),
        ProjectsService.getUserProjects(widget.userId),
        UserService.getUserStats(widget.userId),
        ChangemakersService.getUserImpactStats(widget.userId),
      ]);
      CollabRequestStatus? reqStatus;
      try {
        final existing = await CollaborationService.getRequestStatus(
            otherUserId: widget.userId);
        reqStatus = existing?.status;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _user        = results[0] as UserProfile;
          _projects    = results[1] as List<Project>;
          _stats       = results[2] as Map<String, int>;
          _impactStats = results[3] as Map<String, dynamic>;
          _requestStatus = reqStatus;
          _isLoading   = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        ErrorSnackbar.show(context, appError);
      }
    }
  }

  Future<void> _sendCollabRequest() async {
    setState(() => _sendingRequest = true);
    try {
      await CollaborationService.sendRequest(recipientId: widget.userId);
      if (mounted) {
        setState(() {
          _requestStatus = CollabRequestStatus.pending;
          _sendingRequest = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Connection request sent to ${_user?.name ?? 'user'}!'),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingRequest = false);
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        ErrorSnackbar.show(context, appError);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kTextSecondary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _user?.name ?? 'Profile',
          style: const TextStyle(
              color: _kTextPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_isLoading && _user != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _buildConnectButton(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brightCyan))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.brightCyan,
              backgroundColor: _kCardBg,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStats(),
                    if (_impactStats.isNotEmpty) _buildImpactSection(),
                    if (_user?.bio != null && _user!.bio!.isNotEmpty)
                      _buildDarkSection(
                        'About',
                        Icons.person_outline,
                        _buildBioContent(),
                      ),
                    if (_user?.location != null &&
                        _user!.location!.isNotEmpty)
                      _buildDarkSection(
                        'Location',
                        Icons.location_on_outlined,
                        _buildLocationContent(),
                      ),
                    if (_hasSocialLinks())
                      _buildDarkSection(
                        'Social Links',
                        Icons.link,
                        _buildSocialLinksContent(),
                      ),
                    if (_user?.skills != null &&
                        _user!.skills.isNotEmpty)
                      _buildDarkSection(
                        'Skills',
                        Icons.psychology_outlined,
                        _buildSkillsContent(),
                      ),
                    _buildProjectsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Connect button ────────────────────────────────────────────────────────

  Widget _buildConnectButton() {
    if (_requestStatus == CollabRequestStatus.accepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.forestGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
              color: AppColors.forestGreen.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 13, color: AppColors.forestGreen),
            SizedBox(width: 4),
            Text(
              'Connected',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen),
            ),
          ],
        ),
      );
    }
    if (_requestStatus == CollabRequestStatus.pending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
              color: AppColors.warmAmber.withOpacity(0.4)),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warmAmber),
        ),
      );
    }
    return _sendingRequest
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.brightCyan),
          )
        : GestureDetector(
            onTap: _sendCollabRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          );
  }

  // ── Hero header ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final initial =
        _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B2A),
            AppColors.electricBlue.withOpacity(0.35),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.electricBlue.withOpacity(0.5), width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.electricBlue.withOpacity(0.3),
              backgroundImage: _user?.avatarUrl != null
                  ? NetworkImage(_user!.avatarUrl!)
                  : null,
              child: _user?.avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user?.name ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (_user?.username != null && _user!.username!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@${_user!.username}',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.6)),
            ),
          ],
          const SizedBox(height: 12),
          _buildAvailabilityBadge(_user?.availabilityStatus ?? 'available'),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'busy':
        color = AppColors.rebellionOrange;
        label = 'Busy';
        break;
      case 'not_looking':
        color = AppColors.deepRed;
        label = 'Not Looking';
        break;
      default:
        color = AppColors.forestGreen;
        label = 'Available';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _DarkStatCard(
              label: 'Projects',
              value: (_stats['total_projects'] ?? 0).toString(),
              icon: Icons.folder_outlined,
              color: AppColors.electricBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DarkStatCard(
              label: 'Points',
              value: (_stats['total_likes'] ?? 0).toString(),
              icon: Icons.star_outline,
              color: AppColors.warmAmber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DarkStatCard(
              label: 'Views',
              value: (_stats['profile_views'] ??
                      _user?.profileViews ??
                      0)
                  .toString(),
              icon: Icons.visibility_outlined,
              color: AppColors.brightCyan,
            ),
          ),
        ],
      ),
    );
  }

  // ── Impact section ────────────────────────────────────────────────────────

  Widget _buildImpactSection() {
    final projectsCount = _impactStats['projects_count'] as int? ?? 0;
    final discussionsCount =
        _impactStats['discussions_count'] as int? ?? 0;
    final badges =
        List<String>.from(_impactStats['badges'] as List? ?? []);

    if (projectsCount == 0 && discussionsCount == 0 && badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, size: 18, color: AppColors.warmAmber),
              SizedBox(width: 6),
              Text(
                'Impact & Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _impactChip('$projectsCount Projects',
                  Icons.folder_outlined, AppColors.electricBlue),
              const SizedBox(width: AppSpacing.sm),
              _impactChip('$discussionsCount Discussions',
                  Icons.forum_outlined, AppColors.brightCyan),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: badges
                  .map((b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(
                              color: AppColors.brightCyan.withOpacity(0.3)),
                        ),
                        child: Text(
                          b,
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
        ],
      ),
    );
  }

  Widget _impactChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  // ── Dark section wrapper ──────────────────────────────────────────────────

  Widget _buildDarkSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.brightCyan),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          const SizedBox(height: 12),
          content,
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Section content builders ──────────────────────────────────────────────

  Widget _buildBioContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        _user!.bio!,
        style: const TextStyle(
            fontSize: 14, color: _kTextSecondary, height: 1.55),
      ),
    );
  }

  Widget _buildLocationContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.place_outlined,
              size: 15, color: _kTextSecondary),
          const SizedBox(width: 6),
          Text(
            _user!.location!,
            style: const TextStyle(fontSize: 14, color: _kTextSecondary),
          ),
        ],
      ),
    );
  }

  bool _hasSocialLinks() {
    return (_user?.githubUrl?.isNotEmpty == true) ||
        (_user?.linkedinUrl?.isNotEmpty == true) ||
        (_user?.websiteUrl?.isNotEmpty == true);
  }

  Widget _buildSocialLinksContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_user?.githubUrl?.isNotEmpty == true)
            _socialLinkTile(Icons.code, 'GitHub',
                _user!.githubUrl!, const Color(0xFF6E40C9)),
          if (_user?.linkedinUrl?.isNotEmpty == true)
            _socialLinkTile(Icons.business_center, 'LinkedIn',
                _user!.linkedinUrl!, const Color(0xFF0A66C2)),
          if (_user?.websiteUrl?.isNotEmpty == true)
            _socialLinkTile(Icons.language, 'Website',
                _user!.websiteUrl!, AppColors.brightCyan),
        ],
      ),
    );
  }

  Widget _socialLinkTile(
      IconData icon, String label, String url, Color color) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.open_in_new, size: 13, color: _kTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _user!.skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Projects section ───────────────────────────────────────────────────────

  Widget _buildProjectsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.work_outline,
                    size: 18, color: AppColors.brightCyan),
                const SizedBox(width: 8),
                Text(
                  'Projects (${_projects.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          if (_projects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No projects yet',
                style: TextStyle(color: _kTextSecondary, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              itemCount: _projects.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final project = _projects[index];
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectDetailScreen(projectId: project.id),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252528),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTextSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (project.requiredSkills.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: project.requiredSkills
                                .take(3)
                                .map((skill) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.electricBlue
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusFull),
                                      ),
                                      child: Text(
                                        skill,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.brightCyan,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Dark stat card ────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: _kTextSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
