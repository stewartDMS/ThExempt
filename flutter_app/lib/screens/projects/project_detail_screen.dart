import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/project_model.dart';
import '../../models/project_health.dart';
import '../../services/projects_service.dart';
import '../../theme/app_colors.dart';
import 'applications_screen.dart';
import 'widgets/apply_dialog.dart';
import 'widgets/project_overview_tab.dart';
import 'widgets/project_milestones_tab.dart';
import 'widgets/project_team_tab.dart';
import 'widgets/project_tasks_tab.dart';
import 'widgets/project_analytics_tab.dart';
import 'widgets/project_resources_tab.dart';
import 'widgets/project_activity_tab.dart';
import 'widgets/project_chat_widget.dart';
// Phase 3 tabs
import 'widgets/project_endorsements_tab.dart';
import 'widgets/project_updates_tab.dart';
import 'widgets/project_linked_discussions_tab.dart';
// Phase 4 tabs
import 'widgets/project_investment_tab.dart';
import 'widgets/project_contributors_tab.dart';
import 'widgets/project_equity_tab.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  /// Optional tab index to open on first load (e.g. [investTabIndex] = Invest tab).
  final int initialTabIndex;

  /// Index of the Invest tab – use this when navigating to the invest/contribute flow.
  static const int investTabIndex = 2;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialTabIndex = 0,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

// Compact horizontal tab item: icon to the left of label.
class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TabItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Project? _project;
  ProjectHealth? _health;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _currentUserId;
  String? _currentUserName;

  static final _kTabs = [
    Tab(child: _TabItem(Icons.dashboard_outlined, 'Overview')),
    Tab(child: _TabItem(Icons.flag_outlined, 'Milestones')),
    Tab(child: _TabItem(Icons.trending_up_outlined, 'Invest')),
    Tab(child: _TabItem(Icons.people_outline, 'Team')),
    Tab(child: _TabItem(Icons.thumb_up_alt_outlined, 'Endorsements')),
    Tab(child: _TabItem(Icons.campaign_outlined, 'Updates')),
    Tab(child: _TabItem(Icons.check_circle_outline, 'Tasks')),
    Tab(child: _TabItem(Icons.timeline_outlined, 'Activity')),
    Tab(child: _TabItem(Icons.analytics_outlined, 'Analytics')),
    Tab(child: _TabItem(Icons.folder_outlined, 'Resources')),
    Tab(child: _TabItem(Icons.forum_outlined, 'Discussions')),
    Tab(child: _TabItem(Icons.volunteer_activism_outlined, 'Contributors')),
    Tab(child: _TabItem(Icons.pie_chart_outline, 'Equity')),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _kTabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _kTabs.length - 1),
    );
    _loadCurrentUser();
    _loadProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getString('userId');
        _currentUserName = prefs.getString('userName');
      });
    }
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final project = await ProjectsService.getProject(widget.projectId);
      final health = ProjectHealth.calculate(project);
      if (mounted) {
        setState(() {
          _project = project;
          _health = health;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _showApplyDialog() async {
    if (_project == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ApplyDialog(
        projectId: _project!.id,
        projectTitle: _project!.title,
      ),
    );

    if (result == true) {
      _loadProject();
    }
  }

  bool get _isOwner =>
      _currentUserId != null &&
      _project != null &&
      _currentUserId == _project!.ownerId;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: AppColors.charcoal,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricBlue),
          ),
        ),
      );
    }

    if (_hasError || _project == null) {
      return Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          title: const Text('Project Details'),
          backgroundColor: AppColors.charcoal,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.deepRed.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      size: 48, color: AppColors.deepRed),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Failed to Load Project',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.white60, height: 1.5),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _loadProject,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final project = _project!;
    final health = _health!;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: AppColors.charcoal,
            actions: [
              if (_isOwner)
                IconButton(
                  icon: const Icon(Icons.inbox_outlined),
                  tooltip: 'Applications',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ApplicationsInboxScreen(
                        projectId: project.id,
                        projectTitle: project.title,
                      ),
                    ));
                  },
                ),
              IconButton(
                icon: const Icon(Icons.bookmark_border_outlined),
                tooltip: 'Save project',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share project',
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _ProjectHeader(project: project),
            ),
          ),
          SliverToBoxAdapter(child: _buildHealthBar(health)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _kTabs,
                labelColor: AppColors.brightCyan,
                unselectedLabelColor: Colors.white60,
                indicatorColor: AppColors.electricBlue,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.white12,
              ),
            ),
          ),
        ],
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                // 0 - Overview
                ProjectOverviewTab(project: project, health: health),
                // 1 - Milestones
                ProjectMilestonesTab(project: project, isOwner: _isOwner),
                // 2 - Invest
                ProjectInvestmentTab(
                  project: project,
                  currentUserId: _currentUserId,
                  onProjectUpdated: (updated) {
                    if (mounted) setState(() => _project = updated);
                  },
                ),
                // 3 - Team
                ProjectTeamTab(project: project, isOwner: _isOwner),
                // 4 - Endorsements
                ProjectEndorsementsTab(
                  project: project,
                  currentUserId: _currentUserId,
                  onProjectUpdated: (updated) {
                    if (mounted) setState(() => _project = updated);
                  },
                ),
                // 5 - Updates
                ProjectUpdatesTab(project: project, isOwner: _isOwner),
                // 6 - Tasks
                ProjectTasksTab(project: project, isTeamMember: _isOwner),
                // 7 - Activity
                ProjectActivityTab(project: project),
                // 8 - Analytics
                ProjectAnalyticsTab(project: project),
                // 9 - Resources
                ProjectResourcesTab(project: project),
                // 10 - Discussions
                ProjectLinkedDiscussionsTab(
                    project: project, isOwner: _isOwner),
                // 11 - Contributors
                ProjectContributorsTab(
                  project: project,
                  currentUserId: _currentUserId,
                  isOwner: _isOwner,
                ),
                // 12 - Equity
                ProjectEquityTab(
                  project: project,
                  isOwner: _isOwner,
                ),
              ],
            ),
            // Floating team chat (only visible to the project owner)
            if (_isOwner)
              ProjectChatWidget(
                project: project,
                currentUserId: _currentUserId,
                currentUserName: _currentUserName,
              ),
          ],
        ),
      ),
      bottomNavigationBar: !_isOwner
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  border: Border(
                    top: BorderSide(color: Colors.white12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.electricBlue,
                              AppColors.brightCyan
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _tabController.animateTo(
                                ProjectDetailScreen.investTabIndex);
                          },
                          icon: const Icon(Icons.volunteer_activism, size: 18),
                          label: const Text('Contribute'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _showApplyDialog,
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Apply'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brightCyan,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: AppColors.brightCyan, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHealthBar(ProjectHealth health) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: health.scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.favorite, color: health.scoreColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Health: ${health.scoreLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: health.overallScore / 100),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white12,
                        valueColor:
                            AlwaysStoppedAnimation(health.scoreColor),
                        minHeight: 8,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${health.overallScore.toInt()}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: health.scoreColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Project header (flexible space bar background)
// ---------------------------------------------------------------------------

class _ProjectHeader extends StatelessWidget {
  final Project project;

  const _ProjectHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (project.thumbnailUrl != null && project.thumbnailUrl!.isNotEmpty)
          Image.network(
            project.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _gradientBackground(project.stage.color),
          )
        else
          _gradientBackground(project.stage.color),
        // Multi-stop gradient overlay for better readability
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0x55000000),
                Color(0xCC000000),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stage pill badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: project.stage.color.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${project.stage.emoji} ${project.stage.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                project.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundImage: project.ownerAvatarUrl != null &&
                            project.ownerAvatarUrl!.isNotEmpty
                        ? NetworkImage(project.ownerAvatarUrl!)
                        : null,
                    backgroundColor: Colors.white24,
                    child: project.ownerAvatarUrl == null ||
                            project.ownerAvatarUrl!.isEmpty
                        ? Text(
                            project.ownerName.isNotEmpty
                                ? project.ownerName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project.ownerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gradientBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.charcoal,
            color.withOpacity(0.7),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab bar sliver delegate
// ---------------------------------------------------------------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.charcoal,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
