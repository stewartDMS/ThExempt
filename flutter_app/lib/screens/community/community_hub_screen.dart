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
import '../profile/expert_profile_screen.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF14141A);
const _kCardBg   = Color(0xFF1C1C1E);
const _kDivider  = Color(0xFF2C2C2F);
const _kBorder   = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  List<LiveEvent> _liveNow     = [];
  List<Discussion> _discussions = [];
  bool _loading = true;
  AppError? _error;

  String _activeFilter = 'trending';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        LiveEventsService.getLiveEvents(status: 'live'),
        DiscussionsService.getDiscussions(
            sort: _activeFilter == 'my_posts' ? 'recent' : _activeFilter),
      ]);
      if (mounted) {
        setState(() {
          _liveNow      = results[0] as List<LiveEvent>;
          _discussions  = results[1] as List<Discussion>;
          _loading      = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        setState(() { _loading = false; _error = appError; });
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.brightCyan,
        backgroundColor: _kCardBg,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),

            // ── Filter tabs ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildFilterTabs()),

            // ── Live Now ────────────────────────────────────────────────
            if (_liveNow.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildLiveNowSection()),
              const SliverToBoxAdapter(
                child: SizedBox(height: 2),
              ),
            ],

            // ── Feed ────────────────────────────────────────────────────
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const SkeletonDiscussionCard(),
                  childCount: 5,
                ),
              )
            else if (_error != null && _discussions.isEmpty)
              SliverToBoxAdapter(
                child: ErrorStateWidget(error: _error!, onRetry: _loadData),
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
                        DiscussionFeedCard(
                          discussion: d,
                          onDeleted: () => setState(() => _discussions.remove(d)),
                        ),
                        const Divider(height: 1, color: _kDivider, thickness: 1),
                      ],
                    );
                  },
                  childCount: _discussions.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomNavWithFabPadding),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        _AppBarAction(
          icon: Icons.category_outlined,
          tooltip: 'Browse Categories',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const DiscussionCategoriesScreen()),
          ),
        ),
        _AppBarAction(
          icon: Icons.history_outlined,
          tooltip: 'My Discussions',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyDiscussionsScreen()),
          ),
        ),
        _AppBarAction(
          icon: Icons.live_tv_outlined,
          tooltip: 'Live Events',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EventsHomeScreen()),
          ),
        ),
        _AppBarAction(
          icon: Icons.verified_outlined,
          tooltip: 'My Expertise',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpertProfileScreen()),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D1B2A),
                AppColors.electricBlue.withOpacity(0.3),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.forum_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Community',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary,
                        ),
                      ),
                      Text(
                        'Join the conversation. Drive change.',
                        style: TextStyle(
                            fontSize: 12, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter tabs ────────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    const filters = [
      _FilterTab(value: 'trending', emoji: '🔥', label: 'Trending'),
      _FilterTab(value: 'recent',   emoji: '🕐', label: 'Recent'),
      _FilterTab(value: 'my_posts', emoji: '✍️', label: 'My Posts'),
    ];

    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onFilterChanged(f.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.electricBlue.withOpacity(0.2)
                      : _kCardBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brightCyan.withOpacity(0.6)
                        : _kBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.brightCyan
                            : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Live Now ───────────────────────────────────────────────────────────────

  Widget _buildLiveNowSection() {
    return Container(
      color: _kBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                // Pulsing red dot
                _PulsingDot(),
                const SizedBox(width: 8),
                const Text(
                  'Live Now',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
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
                      color: AppColors.brightCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
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

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.electricBlue.withOpacity(0.2),
                  AppColors.brightCyan.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                  color: AppColors.electricBlue.withOpacity(0.3)),
            ),
            child: const Icon(Icons.forum_outlined,
                size: 36, color: AppColors.brightCyan),
          ),
          const SizedBox(height: 16),
          const Text(
            'No discussions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to start a conversation!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _kTextSecondary),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CreateDiscussionScreen()),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Start Discussion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FilterTab {
  final String value;
  final String emoji;
  final String label;
  const _FilterTab(
      {required this.value, required this.emoji, required this.label});
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarAction(
      {required this.icon,
      required this.tooltip,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: _kTextSecondary, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.deepRed.withOpacity(_anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.deepRed.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
