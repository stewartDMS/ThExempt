import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../services/projects_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/skeleton_project_card.dart';
import '../../widgets/common/load_more_indicator.dart';
import 'widgets/project_card.dart';

class ProjectsFeedScreen extends StatefulWidget {
  const ProjectsFeedScreen({super.key});

  @override
  State<ProjectsFeedScreen> createState() => ProjectsFeedScreenState();
}

// ── Category filter chips data ────────────────────────────────────────────────

const _kCategories = [
  ('All', Icons.apps_rounded),
  ('Ideation', Icons.lightbulb_outline),
  ('MVP', Icons.rocket_launch_outlined),
  ('Growth', Icons.trending_up_outlined),
  ('Funded', Icons.monetization_on_outlined),
  ('Hiring', Icons.group_add_outlined),
];

class ProjectsFeedScreenState extends State<ProjectsFeedScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  AppError? _error;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final projects = await ProjectsService.getProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e is AppError ? e : ErrorHandler.handleError(e);
        });
      }
    }
  }

  Future<void> refreshProjects() => _loadProjects();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: CustomScrollView(
        slivers: [
          // ── Branded app bar ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 110,
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_outlined, color: Colors.white70),
                tooltip: 'Filter & Sort',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined,
                    color: Colors.white70),
                tooltip: 'Notifications',
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _FeedHeader(),
            ),
          ),

          // ── Category chips ──────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryBarDelegate(
              selectedIndex: _selectedCategory,
              onSelected: (i) => setState(() => _selectedCategory = i),
            ),
          ),

          // ── Feed content ────────────────────────────────────────────────
          ..._buildContent(),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_isLoading) {
      return [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const SkeletonProjectCard(),
            childCount: 3,
          ),
        ),
      ];
    }

    if (_error != null && _projects.isEmpty) {
      return [
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.only(
                bottom: AppSpacing.bottomNavWithFabPadding),
            child: _DarkErrorState(error: _error!, onRetry: _loadProjects),
          ),
        ),
      ];
    }

    if (_projects.isEmpty) {
      return [
        SliverFillRemaining(
          child: _DarkEmptyState(onRefresh: _loadProjects),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == _projects.length) {
                return const LoadMoreIndicator();
              }
              return ProjectCard(
                key: ValueKey(_projects[index].id),
                project: _projects[index],
                onDeleted: () {
                  setState(() => _projects.removeAt(index));
                },
              );
            },
            childCount:
                _projects.length + (_isLoadingMore ? 1 : 0),
          ),
        ),
      ),
    ];
  }
}

// ── Feed hero header ────────────────────────────────────────────────────────

class _FeedHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), AppColors.steelGray],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (rect) =>
                    AppColors.primaryGradient.createShader(rect),
                child: const Text(
                  'ThExempt',
                  style: TextStyle(
                    fontSize: 26,
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
                  color: AppColors.rebellionOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.rebellionOrange.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  '🚀 Projects',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rebellionOrange,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Discover & support changemakers',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category filter bar ─────────────────────────────────────────────────────

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryBarDelegate({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const double _kHeight = 50.0;

  @override
  double get minExtent => _kHeight;
  @override
  double get maxExtent => _kHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: _kHeight,
      color: const Color(0xFF1A1A1A),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, icon) = _kCategories[i];
          final isActive = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  Icon(
                    icon,
                    size: 14,
                    color: isActive
                        ? AppColors.brightCyan
                        : Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isActive
                          ? AppColors.brightCyan
                          : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryBarDelegate old) =>
      old.selectedIndex != selectedIndex;
}

// ── Dark empty state ─────────────────────────────────────────────────────────

class _DarkEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DarkEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32,
            AppSpacing.bottomNavWithFabPadding),
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
              child: const Icon(Icons.work_outline,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Projects Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to share your vision\nwith the community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
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

// ── Dark error state ─────────────────────────────────────────────────────────

class _DarkErrorState extends StatelessWidget {
  final AppError error;
  final VoidCallback onRetry;
  const _DarkErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
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
    );
  }
}
