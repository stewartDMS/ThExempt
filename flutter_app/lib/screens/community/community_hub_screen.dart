import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../models/live_event_model.dart';
import '../../services/discussions_service.dart';
import '../../services/live_events_service.dart';
import '../../widgets/common/discussion_feed_card.dart';
import '../../widgets/common/skeleton_discussion_card.dart';
import '../../widgets/live_event_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/error_snackbar.dart';
import 'discussion_categories_screen.dart';
import 'create_discussion_screen.dart';
import 'my_discussions_screen.dart';
import '../live_events/events_home_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  List<LiveEvent> _liveNow = [];
  List<Discussion> _discussions = [];
  bool _loading = true;
  AppError? _error;

  // Filter tabs: trending, recent, following, my_posts
  String _activeFilter = 'trending';

  static const _filters = [
    (key: 'trending', label: '🔥 Trending'),
    (key: 'recent', label: '🕐 Recent'),
    (key: 'my_posts', label: '✍️ My Posts'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        LiveEventsService.getLiveEvents(status: 'live'),
        DiscussionsService.getDiscussions(
            sort: _activeFilter == 'my_posts' ? 'recent' : _activeFilter),
      ]);
      if (mounted) {
        setState(() {
          _liveNow = results[0] as List<LiveEvent>;
          _discussions = results[1] as List<Discussion>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        setState(() {
          _loading = false;
          _error = appError;
        });
        // Show snackbar when we already have data
        if (_discussions.isNotEmpty) {
          ErrorSnackbar.show(context, appError, onRetry: _loadData);
        }
      }
    }
  }

  void _onFilterChanged(String filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Browse Categories',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const DiscussionCategoriesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'My Discussions',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyDiscussionsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.live_tv_outlined),
            tooltip: 'Live Events',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventsHomeScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Filter chips ───────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildFilterChips()),

            const SliverToBoxAdapter(child: Divider(height: 1)),

            // ── Live Now section ──────────────────────────────────────────
            if (_liveNow.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildLiveNowSection()),
              const SliverToBoxAdapter(
                child: Divider(height: 8, color: AppColors.scaffoldBackground),
              ),
            ],

            // ── Discussion feed ────────────────────────────────────────────
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const SkeletonDiscussionCard(),
                  childCount: 5,
                ),
              )
            else if (_error != null && _discussions.isEmpty)
              SliverToBoxAdapter(
                child: ErrorStateWidget(
                  error: _error!,
                  onRetry: _loadData,
                ),
              )
            else if (_discussions.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final d = _discussions[index];
                    return Column(
                      children: [
                        DiscussionFeedCard(discussion: d),
                        const Divider(
                            height: 1, color: AppColors.scaffoldBackground, thickness: 8),
                      ],
                    );
                  },
                  childCount: _discussions.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.bottomNavWithFabPadding)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: _filters.map((f) {
          final isActive = _activeFilter == f.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onFilterChanged(f.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.white : AppColors.grey600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLiveNowSection() {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Live Now',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EventsHomeScreen()),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _liveNow.length,
              itemBuilder: (_, i) => SizedBox(
                width: 280,
                child: LiveEventCard(event: _liveNow[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(Icons.forum_outlined,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No discussions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to start a conversation!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const CreateDiscussionScreen()),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Start Discussion'),
          ),
        ],
      ),
    );
  }
}
