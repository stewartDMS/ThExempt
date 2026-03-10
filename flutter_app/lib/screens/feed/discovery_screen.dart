import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/project_model.dart';
import '../../services/projects_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/role_category_filter.dart';
import '../../widgets/best_matches_section.dart';
import '../../widgets/discovery_project_card.dart';

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
  bool _hasError = false;
  String _errorMessage = '';

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
      _hasError = false;
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
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
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
            icon: const Icon(Icons.sort),
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
          // ── Category filter chips ──────────────────────────────────────
          const SizedBox(height: 8),
          RoleCategoryFilter(
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),

          // ── "Only open roles" toggle ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.work_outline,
                    size: 16, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text(
                  'Only show projects with open roles',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _onlyOpenRoles,
                  onChanged: (v) {
                    setState(() => _onlyOpenRoles = v);
                    _loadData();
                  },
                  activeColor: Colors.green[600],
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

  Widget _buildSortChips() {
    final labels = {
      'recent': 'Recent',
      'match': 'Best Match',
      'needed': 'Most Needed',
    };
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: labels.entries.map((e) {
          final isSelected = _sort == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: isSelected,
              onSelected: (_) => _onSortChanged(e.key),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              showCheckmark: false,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    final filtered = _filteredProjects;
    final bestMatches = _bestMatches;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
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
          return DiscoveryProjectCard(
            key: ValueKey(project.id),
            project: project,
            matchScore: score,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != null
                  ? 'No ${_selectedCategory!} projects match your filters.\nTry a different category or turn off the open-roles filter.'
                  : 'No projects match your current filters.\nTry adjusting them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Projects',
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
