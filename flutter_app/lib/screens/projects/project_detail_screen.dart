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

// ---------------------------------------------------------------------------
// Tab metadata
// ---------------------------------------------------------------------------

class _TabMeta {
  final IconData icon;
  final String label;
  const _TabMeta(this.icon, this.label);
}

const _kTabMeta = [
  _TabMeta(Icons.dashboard_outlined, 'Overview'),             // 0
  _TabMeta(Icons.flag_outlined, 'Milestones'),                // 1
  _TabMeta(Icons.trending_up_outlined, 'Invest'),             // 2
  _TabMeta(Icons.people_outline, 'Team'),                     // 3
  _TabMeta(Icons.thumb_up_alt_outlined, 'Endorsements'),      // 4
  _TabMeta(Icons.campaign_outlined, 'Updates'),               // 5
  _TabMeta(Icons.check_circle_outline, 'Tasks'),              // 6
  _TabMeta(Icons.timeline_outlined, 'Activity'),              // 7
  _TabMeta(Icons.analytics_outlined, 'Analytics'),            // 8
  _TabMeta(Icons.folder_outlined, 'Resources'),               // 9
  _TabMeta(Icons.forum_outlined, 'Discussions'),              // 10
  _TabMeta(Icons.volunteer_activism_outlined, 'Contributors'), // 11
  _TabMeta(Icons.pie_chart_outline, 'Equity'),                // 12
];

/// Indices shown directly in the primary nav bar (the 5 most-used sections).
const _kPrimaryTabIndices = [0, 1, 2, 3, 5];

/// Indices accessible through the "More" overflow sheet.
const _kSecondaryTabIndices = [4, 6, 7, 8, 9, 10, 11, 12];

// ---------------------------------------------------------------------------
// Screen widget
// ---------------------------------------------------------------------------

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _kTabMeta.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _kTabMeta.length - 1),
    );
    // Rebuild the nav bar whenever the tab changes (includes programmatic animateTo).
    _tabController.addListener(_onTabChange);
    _loadCurrentUser();
    _loadProject();
  }

  void _onTabChange() {
    // Rebuild the nav bar to update the active-tab highlight.
    if (!_tabController.indexIsChanging && mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
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
            delegate: _PrimaryNavDelegate(
              currentIndex: _tabController.index,
              onTabSelected: (i) => _tabController.animateTo(i),
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
          colors: [AppColors.charcoal, color.withOpacity(0.7)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary navigation bar – 5 pinned tabs + "More" overflow
// ---------------------------------------------------------------------------

class _PrimaryNavDelegate extends SliverPersistentHeaderDelegate {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _PrimaryNavDelegate({
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const double _kBarHeight = 64.0;

  bool get _isSecondaryActive =>
      !_kPrimaryTabIndices.contains(currentIndex);

  @override
  double get minExtent => _kBarHeight;

  @override
  double get maxExtent => _kBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _kBarHeight - 1,
            child: Row(
              children: [
                // Five primary tab items
                ..._kPrimaryTabIndices.map((tabIndex) {
                  final meta = _kTabMeta[tabIndex];
                  return _PrimaryNavItem(
                    icon: meta.icon,
                    label: meta.label,
                    isActive: currentIndex == tabIndex,
                    onTap: () => onTabSelected(tabIndex),
                  );
                }),
                // "More" overflow button
                _MoreNavItem(
                  isActive: _isSecondaryActive,
                  activeLabel: _isSecondaryActive
                      ? _kTabMeta[currentIndex].label
                      : null,
                  onTap: () => _openMoreSheet(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2C2C2C)),
        ],
      ),
    );
  }

  void _openMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF252525),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoreTabsSheet(
        currentIndex: currentIndex,
        onTabSelected: (i) {
          Navigator.of(context).pop();
          onTabSelected(i);
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_PrimaryNavDelegate old) =>
      old.currentIndex != currentIndex;
}

// Individual primary tab item: icon above label, equal-width columns.
class _PrimaryNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PrimaryNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brightCyan : const Color(0xFF7A7A7A);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brightCyan.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.electricBlue.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// "More ···" overflow button.  Shows the active secondary tab name when one
// is selected so the user always knows where they are.
class _MoreNavItem extends StatelessWidget {
  final bool isActive;
  final String? activeLabel;
  final VoidCallback onTap;

  const _MoreNavItem({
    required this.isActive,
    required this.onTap,
    this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brightCyan : const Color(0xFF7A7A7A);
    final displayLabel =
        (isActive && activeLabel != null) ? activeLabel! : 'More';

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brightCyan.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.electricBlue.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.apps_outlined,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "More" bottom sheet – 4-column grid of secondary tabs
// ---------------------------------------------------------------------------

class _MoreTabsSheet extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _MoreTabsSheet({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'MORE SECTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: _kSecondaryTabIndices.map((i) {
                final meta = _kTabMeta[i];
                return _SheetTabCard(
                  icon: meta.icon,
                  label: meta.label,
                  isActive: currentIndex == i,
                  onTap: () => onTabSelected(i),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTabCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SheetTabCard({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? AppColors.electricBlue.withOpacity(0.22)
        : const Color(0xFF333333);
    final iconColor = isActive ? AppColors.brightCyan : Colors.white70;
    final textColor = isActive ? AppColors.brightCyan : Colors.white60;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.electricBlue.withOpacity(0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(
                    color: AppColors.electricBlue.withOpacity(0.5),
                    width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: iconColor),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
