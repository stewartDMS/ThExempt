import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/project_model.dart';
import '../../services/projects_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/role_category_filter.dart';
import '../../widgets/best_matches_section.dart';
import '../../widgets/discovery_project_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/skeleton_project_card.dart';
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

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    _loadData();
  }

  void _onSortChanged(String? sort) {
    if (sort == null) return;
    setState(() => _sort = sort);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Sort',
            onSelected: _onSortChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'recent',
                child: Row(children: [
                  Icon(Icons.access_time, size: 18),
                  SizedBox(width: 8),
                  Text('Most Recent'),
                ]),
              ),
              PopupMenuItem(
                value: 'match',
                child: Row(children: [
                  Icon(Icons.star_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Best Match'),
                ]),
              ),
              PopupMenuItem(
                value: 'needed',
                child: Row(children: [
                  Icon(Icons.group_add_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Most Needed'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search hint bar ───────────────────────────────────────────
          _buildSearchHint(),

          // ── Category filter chips ──────────────────────────────────────
          RoleCategoryFilter(
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),

          // ── "Only open roles" toggle ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(Icons.work_outline,
                    size: AppSpacing.iconSm + 2,
                    color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Only show projects with open roles',
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.grey700, fontSize: 13),
                ),
                const Spacer(),
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
          ),

          const Divider(height: 1),

          // ── Sort chip (compact inline display) ────────────────────────
          _buildSortChips(),

          // ── Main content ──────────────────────────────────────────────
          Expanded(child: _buildBody()),
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

  Widget _buildSortChips() {
    final labels = {
      'recent': 'Recent',
      'match': 'Best Match',
      'needed': 'Most Needed',
    };
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        children: labels.entries.map((e) {
          final isSelected = _sort == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSelected,
              onSelected: (_) => _onSortChanged(e.key),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.grey100,
              labelStyle: AppTextStyles.captionMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.primary,
                fontSize: 12,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.grey200,
              ),
            ),
          );
        }).toList(),
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
