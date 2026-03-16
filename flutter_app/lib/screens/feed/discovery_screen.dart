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
import '../../theme/text_styles.dart';
import '../../widgets/common/skeleton_project_card.dart';
import '../../widgets/common/filter_dropdown.dart';
import '../../widgets/common/filter_panel.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/error_snackbar.dart';

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

class _DiscoveryScreenState extends State<DiscoveryScreen> {
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
    _loadData();
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
      appBar: AppBar(
        title: const Text('Discover'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search hint bar ───────────────────────────────────────────
          _buildSearchHint(),

          // ── Dropdown filter panel ─────────────────────────────────────
          _buildFilters(),

          // ── Main content ──────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return FilterPanel(
      child: Column(
        children: [
          // Category dropdown
          FilterDropdown<String?>(
            label: 'Category',
            value: _selectedCategory,
            items: const [
              DropdownItem(
                  value: null,
                  label: 'All Categories',
                  icon: Icons.grid_view_outlined),
              DropdownItem(
                  value: 'Technical',
                  label: 'Technical',
                  icon: Icons.code),
              DropdownItem(
                  value: 'Business',
                  label: 'Business',
                  icon: Icons.business_center_outlined),
              DropdownItem(
                  value: 'Marketing',
                  label: 'Marketing',
                  icon: Icons.campaign_outlined),
              DropdownItem(
                  value: 'Design',
                  label: 'Design',
                  icon: Icons.brush_outlined),
              DropdownItem(
                  value: 'Finance',
                  label: 'Finance',
                  icon: Icons.attach_money),
              DropdownItem(
                  value: 'Operations',
                  label: 'Operations',
                  icon: Icons.settings_outlined),
              DropdownItem(
                  value: 'Legal', label: 'Legal', icon: Icons.gavel_outlined),
              DropdownItem(
                  value: 'Other',
                  label: 'Other',
                  icon: Icons.more_horiz),
            ],
            onChanged: (value) {
              setState(() => _selectedCategory = value);
              _loadData();
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Stage dropdown
          FilterDropdown<ProjectStage?>(
            label: 'Project Stage',
            value: _selectedStage,
            items: [
              const DropdownItem(
                  value: null,
                  label: 'All Stages',
                  icon: Icons.layers_outlined),
              ...ProjectStage.values.map(
                (stage) => DropdownItem(
                  value: stage,
                  label: '${stage.emoji} ${stage.displayName}',
                  color: stage.color,
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedStage = value);
              _loadData();
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Sort dropdown
          FilterDropdown<String>(
            label: 'Sort By',
            value: _sort,
            items: const [
              DropdownItem(
                  value: 'recent',
                  label: 'Most Recent',
                  icon: Icons.schedule_outlined),
              DropdownItem(
                  value: 'match',
                  label: 'Best Match',
                  icon: Icons.star_outline),
              DropdownItem(
                  value: 'needed',
                  label: 'Most Needed',
                  icon: Icons.group_add_outlined),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _sort = value);
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Open roles toggle
          Row(
            children: [
              Icon(Icons.work_outline,
                  size: AppSpacing.iconSm + 2, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Only show projects with open roles',
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.grey700, fontSize: 13),
                ),
              ),
              Switch.adaptive(
                value: _onlyOpenRoles,
                onChanged: (v) {
                  setState(() => _onlyOpenRoles = v);
                  _loadData();
                },
                activeColor: AppColors.success,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: GestureDetector(
        onTap: () {}, // Future: open search
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.grey200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.grey400, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Search projects, skills...',
                style: AppTextStyles.body2.copyWith(color: AppColors.grey400),
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
        child: ErrorStateWidget(error: _error!, onRetry: _loadData),
      );
    }

    final filtered = _filteredProjects;
    final bestMatches = _bestMatches;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
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
                  height: 8,
                  color: AppColors.scaffoldBackground,
                  thickness: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              ),
              child: const Icon(Icons.search_off,
                  size: AppSpacing.iconXxl, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No projects found',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedCategory != null
                  ? 'No ${_selectedCategory!} projects match your filters.\nTry a different category or turn off the open-roles filter.'
                  : 'No projects match your current filters.\nTry adjusting them.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: AppSpacing.xl),
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
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
