import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/project_model.dart';
import '../../models/project_health.dart';
import '../../services/projects_service.dart';
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

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
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

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
    Tab(icon: Icon(Icons.flag_outlined), text: 'Milestones'),
    Tab(icon: Icon(Icons.people_outline), text: 'Team'),
    Tab(icon: Icon(Icons.check_circle_outline), text: 'Tasks'),
    Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
    Tab(icon: Icon(Icons.folder_outlined), text: 'Resources'),
    Tab(icon: Icon(Icons.timeline_outlined), text: 'Activity'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        appBar: AppBar(
          title: const Text('Loading...'),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details'), elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Load Project',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadProject,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
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
                tabs: _tabs,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                indicatorSize: TabBarIndicatorSize.label,
              ),
            ),
          ),
        ],
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                ProjectOverviewTab(project: project, health: health),
                ProjectMilestonesTab(project: project),
                ProjectTeamTab(project: project, isOwner: _isOwner),
                ProjectTasksTab(project: project, isTeamMember: _isOwner),
                ProjectAnalyticsTab(project: project),
                ProjectResourcesTab(project: project),
                ProjectActivityTab(project: project),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _showApplyDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply to Project',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHealthBar(ProjectHealth health) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: health.scoreColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: health.scoreColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Health: ${health.scoreLabel}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: health.overallScore / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(health.scoreColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${health.overallScore.toInt()}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
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
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: project.stage.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${project.stage.emoji} ${project.stage.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                project.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
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
                  const SizedBox(width: 6),
                  Text(
                    project.ownerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
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
          colors: [color, color.withOpacity(0.6)],
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
