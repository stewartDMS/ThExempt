import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/project_model.dart';
import '../../models/project_stage.dart';
import '../../services/projects_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/best_matches_section.dart';
import '../../widgets/discovery_project_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/skeleton_project_card.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_snackbar.dart';
import '../discovery/changemakers_screen.dart';
import '../discovery/skills_marketplace_screen.dart';
import '../discovery/community_map_screen.dart';

/// Calculates how well a user profile matches a given project.
/// Returns an integer score in the range [0, 100].
int _calculateMatchScore(UserProfile user, Project project) {
  final userSkills = user.skills.map((s) => s.toLowerCase()).toSet();
  if (userSkills.isEmpty || project.requiredSkills.isEmpty) return 0;

  final projectSkills =
      project.requiredSkills.map((s) => s.toLowerCase()).toSet();
  final matching = userSkills.intersection(projectSkills);
  return ((matching.length / projectSkills.length) * 100).round();
}

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  // ─── Tab ──────────────────────────────────────────────────────────────────
  late TabController _tabController;
  // ─── State ────────────────────────────────────────────────────────────────
  List<Project> _allProjects = [];
  UserProfile? _currentUser;
  bool _isLoading = true;
  AppError? _error;

  // Filters / sort
  String? _selectedCategory;
  ProjectStage? _selectedStage;
  bool _onlyOpenRoles = false;
  String _sort = 'recent'; // 'recent' | 'match' | 'needed'

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user profile for match calculation (best effort)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        try {
          _currentUser = await UserService.getProfile(userId);
        } catch (_) {
          // Non-critical – discovery still works without a user profile
        }
      }

      final projects = await ProjectsService.discoverProjects(
        roleCategory: _selectedCategory,
        hasOpenRoles: _onlyOpenRoles,
        sort: _sort,
        stage: _selectedStage,
      );

      if (mounted) {
        setState(() {
          _allProjects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        setState(() {
          _isLoading = false;
          _error = appError;
        });
        // Show snackbar for minor errors when we have cached data
        if (appError.type != ErrorType.network && _allProjects.isNotEmpty) {
          ErrorSnackbar.show(context, appError, onRetry: _loadData);
        }
      }
    }
  }

  // ─── Computed values ──────────────────────────────────────────────────────

  /// Filtered + sorted list based on current filter/sort state.
  /// Category and open-roles filtering is primarily handled server-side via
  /// [ProjectsService.discoverProjects]. Client-side, we only apply the
  /// open-roles guard (a fast, accurate check using local data) and sorting.
  List<Project> get _filteredProjects {
    var list = List<Project>.from(_allProjects);

    // Open roles filter (client-side guard)
    if (_onlyOpenRoles) {
      list = list
          .where((p) => p.totalRolesNeeded - p.rolesFilled > 0)
          .toList();
    }

    // Sort
    switch (_sort) {
      case 'match':
        if (_currentUser != null) {
          // Pre-compute scores to avoid O(n²) recalculations during sort
          final scores = {
            for (final p in list)
              p.id: _calculateMatchScore(_currentUser!, p)
          };
          list.sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));
        }
      case 'needed':
        list.sort((a, b) =>
            (b.totalRolesNeeded - b.rolesFilled)
                .compareTo(a.totalRolesNeeded - a.rolesFilled));
      case 'recent':
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  /// Top-5 best-matching projects for "Best Matches For You" section.
  List<({Project project, int matchScore, List<String> openRoleTitles})>
      get _bestMatches {
    if (_currentUser == null) return [];

    final scored = _allProjects
        .map((p) => (
              project: p,
              matchScore: _calculateMatchScore(_currentUser!, p),
              openRoleTitles: <String>[],
            ))
        .where((m) => m.matchScore > 0)
        .toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return scored.take(5).toList();
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (rect) =>
                  AppColors.primaryGradient.createShader(rect),
              child: const Text(
                'ThExempt',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brightCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.brightCyan.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: const Text(
                '🔍 Discover',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brightCyan,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brightCyan,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.brightCyan,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          isScrollable: true,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Projects'),
            Tab(text: 'Changemakers'),
            Tab(text: 'Skills'),
            Tab(text: 'Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjectsTab(),
          const ChangemakersScreen(),
          const SkillsMarketplaceScreen(),
          const CommunityMapScreen(),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search hint bar ───────────────────────────────────────────
        _buildSearchHint(),

        // ── Dropdown filter panel ─────────────────────────────────────
        _buildFilters(),

        // ── Main content ──────────────────────────────────────────────
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ── Category ──────────────────────────────────────────────────
            PopupMenuButton<String?>(
              color: const Color(0xFF2C2C2C),
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                setState(() => _selectedCategory = v);
                _loadData();
              },
              itemBuilder: (_) => [
                _darkMenuItem<String?>(null, 'All Categories'),
                _darkMenuItem('Technical', 'Technical'),
                _darkMenuItem('Business', 'Business'),
                _darkMenuItem('Marketing', 'Marketing'),
                _darkMenuItem('Design', 'Design'),
                _darkMenuItem('Finance', 'Finance'),
                _darkMenuItem('Operations', 'Operations'),
                _darkMenuItem('Legal', 'Legal'),
                _darkMenuItem('Other', 'Other'),
              ],
              child: _FilterChip(
                label: _selectedCategory ?? 'Category',
                icon: Icons.grid_view_outlined,
                isActive: _selectedCategory != null,
              ),
            ),
            const SizedBox(width: 8),
            // ── Stage ─────────────────────────────────────────────────────
            PopupMenuButton<String>(
              color: const Color(0xFF2C2C2C),
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                setState(() => _selectedStage = v.isEmpty
                    ? null
                    : ProjectStage.values
                        .firstWhere((s) => s.name == v,
                            orElse: () => ProjectStage.values.first));
                _loadData();
              },
              itemBuilder: (_) => [
                _darkMenuItem('', 'All Stages'),
                ...ProjectStage.values.map(
                  (s) => _darkMenuItem(s.name, '${s.emoji} ${s.displayName}'),
                ),
              ],
              child: _FilterChip(
                label: _selectedStage != null
                    ? '${_selectedStage!.emoji} ${_selectedStage!.displayName}'
                    : 'Stage',
                icon: Icons.layers_outlined,
                isActive: _selectedStage != null,
              ),
            ),
            const SizedBox(width: 8),
            // ── Sort ──────────────────────────────────────────────────────
            PopupMenuButton<String>(
              color: const Color(0xFF2C2C2C),
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                setState(() => _sort = v);
                _loadData();
              },
              itemBuilder: (_) => [
                _darkMenuItem('recent', 'Most Recent'),
                _darkMenuItem('match', 'Best Match'),
                _darkMenuItem('needed', 'Most Needed'),
              ],
              child: _FilterChip(
                label: _sortLabel,
                icon: Icons.sort,
                isActive: _sort != 'recent',
              ),
            ),
            const SizedBox(width: 8),
            // ── Open Roles toggle ─────────────────────────────────────────
            GestureDetector(
              onTap: () {
                setState(() => _onlyOpenRoles = !_onlyOpenRoles);
                _loadData();
              },
              child: _FilterChip(
                label: 'Open Roles',
                icon: Icons.work_outline,
                isActive: _onlyOpenRoles,
                showArrow: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<T> _darkMenuItem<T>(T value, String label) {
    return PopupMenuItem<T>(
      value: value,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  String get _sortLabel => switch (_sort) {
        'match' => 'Best Match',
        'needed' => 'Most Needed',
        _ => 'Most Recent',
      };

  Widget _buildSearchHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.white38, size: 20),
              SizedBox(width: 10),
              Text(
                'Search projects, skills…',
                style: TextStyle(fontSize: 14, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: 4,
        itemBuilder: (_, __) => const SkeletonProjectCard(),
      );
    }

    if (_error != null && _allProjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavWithFabPadding),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
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
                      size: 40, color: AppColors.deepRed),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white54, height: 1.5),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brightCyan,
                    side: const BorderSide(color: AppColors.brightCyan),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filteredProjects;
    final bestMatches = _bestMatches;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.brightCyan,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: filtered.length + (bestMatches.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // First item: "Best Matches" section (renders its own cards + header)
          if (bestMatches.isNotEmpty && index == 0) {
            return BestMatchesSection(matches: bestMatches);
          }
          final projectIndex =
              bestMatches.isNotEmpty ? index - 1 : index;
          final project = filtered[projectIndex];
          final score = _currentUser != null
              ? _calculateMatchScore(_currentUser!, project)
              : null;
          return Column(
            children: [
              DiscoveryProjectCard(
                key: ValueKey(project.id),
                project: project,
                matchScore: score,
                onDeleted: () {
                  setState(() {
                    _allProjects.remove(project);
                  });
                },
              ),
              const Divider(
                  height: 1,
                  color: Color(0xFF2A2A2A),
                  thickness: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            32, 32, 32, AppSpacing.bottomNavWithFabPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.electricBlue, AppColors.brightCyan],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.search_off,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'No projects found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != null
                  ? 'No ${_selectedCategory!} projects match your filters.\nTry a different category or turn off Open Roles.'
                  : 'No projects match your current filters.\nTry adjusting them.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedStage = null;
                  _onlyOpenRoles = false;
                  _sort = 'recent';
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Dark filter chip ──────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool showArrow;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.electricBlue.withOpacity(0.18)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.electricBlue.withOpacity(0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isActive ? AppColors.brightCyan : Colors.white54),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? AppColors.brightCyan : Colors.white54,
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down,
                size: 13,
                color: isActive ? AppColors.brightCyan : Colors.white38),
          ],
        ],
      ),
    );
  }
}