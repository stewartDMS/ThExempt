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
import '../../theme/text_styles.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_snackbar.dart';

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

      // Check existing collaboration request status (best effort)
      CollabRequestStatus? reqStatus;
      try {
        final existing = await CollaborationService.getRequestStatus(
            otherUserId: widget.userId);
        reqStatus = existing?.status;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _user = results[0] as UserProfile;
          _projects = results[1] as List<Project>;
          _stats = results[2] as Map<String, int>;
          _impactStats = results[3] as Map<String, dynamic>;
          _requestStatus = reqStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
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
            content: Text('Connection request sent to ${_user?.name ?? 'user'}!'),
            backgroundColor: AppColors.success,
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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? 'Profile'),
        elevation: 0,
        actions: [
          if (!_isLoading && _user != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _buildConnectButton(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStats(),
                    _buildImpactSection(),
                    if (_user?.bio != null && _user!.bio!.isNotEmpty)
                      _buildBioSection(),
                    if (_user?.location != null && _user!.location!.isNotEmpty)
                      _buildLocationSection(),
                    if (_hasSocialLinks()) _buildSocialLinks(),
                    if (_user?.skills != null && _user!.skills.isNotEmpty)
                      _buildSkillsSection(),
                    _buildProjectsSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConnectButton() {
    if (_requestStatus == CollabRequestStatus.accepted) {
      return const Chip(
        label: Text('Connected'),
        backgroundColor: AppColors.successLight,
        labelStyle: TextStyle(color: AppColors.success, fontSize: 12),
        padding: EdgeInsets.zero,
      );
    }
    if (_requestStatus == CollabRequestStatus.pending) {
      return const Chip(
        label: Text('Pending'),
        backgroundColor: AppColors.warningLight,
        labelStyle: TextStyle(color: AppColors.warning, fontSize: 12),
        padding: EdgeInsets.zero,
      );
    }
    return _sendingRequest
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          )
        : TextButton(
            onPressed: _sendCollabRequest,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            child: const Text('Connect',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          );
  }

  Widget _buildImpactSection() {
    if (_impactStats.isEmpty) return const SizedBox.shrink();
    final projectsCount = _impactStats['projects_count'] as int? ?? 0;
    final discussionsCount = _impactStats['discussions_count'] as int? ?? 0;
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Impact & Activity',
                  style: AppTextStyles.heading5
                      .copyWith(color: AppColors.grey900)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _impactChip('$projectsCount Projects', Icons.folder_outlined,
                  AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _impactChip('$discussionsCount Discussions',
                  Icons.forum_outlined, AppColors.secondary),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: badges
                  .map((b) => Chip(
                        label: Text(b,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primary)),
                        backgroundColor: AppColors.primaryContainer,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
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
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }

  bool _hasSocialLinks() {
    return (_user?.githubUrl != null && _user!.githubUrl!.isNotEmpty) ||
        (_user?.linkedinUrl != null && _user!.linkedinUrl!.isNotEmpty) ||
        (_user?.websiteUrl != null && _user!.websiteUrl!.isNotEmpty);
  }

  Widget _buildHeader() {
    final initial =
        _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: _user?.avatarUrl != null
                ? NetworkImage(_user!.avatarUrl!)
                : null,
            child: _user?.avatarUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _user?.name ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Username
          if (_user?.username != null && _user!.username!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@${_user!.username}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],

          // Availability status
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
        color = Colors.orange;
        label = 'Busy';
        break;
      case 'not_looking':
        color = Colors.red;
        label = 'Not Looking';
        break;
      default:
        color = Colors.green;
        label = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Projects',
              (_stats['total_projects'] ?? 0).toString(),
              Icons.folder_outlined,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Points',
              (_stats['total_likes'] ?? 0).toString(),
              Icons.star_outline,
              Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Views',
              (_stats['profile_views'] ?? _user?.profileViews ?? 0).toString(),
              Icons.visibility_outlined,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return _buildSection(
      'About',
      Icons.person_outline,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          _user!.bio!,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      'Location',
      Icons.location_on_outlined,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              _user!.location!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return _buildSection(
      'Social Links',
      Icons.link,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            if (_user?.githubUrl != null && _user!.githubUrl!.isNotEmpty)
              _buildSocialLinkTile(
                  Icons.code, 'GitHub', _user!.githubUrl!, Colors.grey[800]!),
            if (_user?.linkedinUrl != null && _user!.linkedinUrl!.isNotEmpty)
              _buildSocialLinkTile(Icons.business_center, 'LinkedIn',
                  _user!.linkedinUrl!, const Color(0xFF0077B5)),
            if (_user?.websiteUrl != null && _user!.websiteUrl!.isNotEmpty)
              _buildSocialLinkTile(Icons.language, 'Website',
                  _user!.websiteUrl!, const Color(0xFF6366F1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinkTile(
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
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.open_in_new, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return _buildSection(
      'Skills',
      Icons.psychology_outlined,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _user!.skills.map((skill) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3)),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProjectsSection() {
    return _buildSection(
      'Projects (${_projects.length})',
      Icons.work_outline,
      _projects.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No projects yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectDetailScreen(projectId: project.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            project.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (project.requiredSkills.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  project.requiredSkills.take(3).map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          content,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
