import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/changemakers_service.dart';
import '../../services/collaboration_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../utils/error_handler.dart';
import '../profile/user_profile_screen.dart';

/// Phase 2 — Changemakers Directory
///
/// Browse and filter impact-focused users by skill, availability, and
/// location. Tap a card to view their full profile and send a collaboration
/// request.
class ChangemakersScreen extends StatefulWidget {
  const ChangemakersScreen({super.key});

  @override
  State<ChangemakersScreen> createState() => _ChangemakersScreenState();
}

class _ChangemakersScreenState extends State<ChangemakersScreen> {
  List<UserProfile> _changemakers = [];
  bool _isLoading = true;
  AppError? _error;

  // Filters
  String _searchQuery = '';
  String? _availabilityFilter;
  String? _locationFilter;
  String _sort = 'reputation';

  final _searchController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final changemakers = await ChangemakersService.getChangemakers(
        skillFilter: _searchQuery.isNotEmpty ? _searchQuery : null,
        availabilityFilter: _availabilityFilter,
        locationFilter:
            _locationFilter?.isNotEmpty == true ? _locationFilter : null,
        sort: _sort,
      );
      if (mounted) {
        setState(() {
          _changemakers = changemakers;
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
      }
    }
  }

  void _onSearch(String value) {
    setState(() => _searchQuery = value);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search by skill (e.g. Design, Policy…)',
              hintStyle:
                  AppTextStyles.body2.copyWith(color: AppColors.grey400),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.grey400, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.grey400, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Filter row
          Row(
            children: [
              _buildFilterChip(
                'Available',
                _availabilityFilter == 'available',
                () => setState(() {
                  _availabilityFilter =
                      _availabilityFilter == 'available' ? null : 'available';
                  _loadData();
                }),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                'Open to Collab',
                _availabilityFilter == 'open_to_collaborate',
                () => setState(() {
                  _availabilityFilter =
                      _availabilityFilter == 'open_to_collaborate'
                          ? null
                          : 'open_to_collaborate';
                  _loadData();
                }),
              ),
              const Spacer(),
              _buildSortButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.grey200),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? AppColors.white : AppColors.grey700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      initialValue: _sort,
      onSelected: (value) {
        setState(() => _sort = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 14, color: AppColors.grey700),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _sort == 'recent' ? 'Recent' : 'Top',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey700, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'reputation', child: Text('Top Reputation')),
        const PopupMenuItem(value: 'recent', child: Text('Recently Joined')),
        const PopupMenuItem(value: 'activity', child: Text('Most Active')),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: 6,
        itemBuilder: (_, __) => const _ChangemakerCardSkeleton(),
      );
    }

    if (_error != null && _changemakers.isEmpty) {
      return ErrorStateWidget(error: _error!, onRetry: _loadData);
    }

    if (_changemakers.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No changemakers found',
        subtitle:
            'Try a different skill search or remove filters to see all members.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: _changemakers.length,
        itemBuilder: (context, index) {
          return _ChangemakerCard(
            user: _changemakers[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    UserProfileScreen(userId: _changemakers[index].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Changemaker Card ──────────────────────────────────────────────────────────

class _ChangemakerCard extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _ChangemakerCard({required this.user, required this.onTap});

  @override
  State<_ChangemakerCard> createState() => _ChangemakerCardState();
}

class _ChangemakerCardState extends State<_ChangemakerCard> {
  bool _requesting = false;

  Future<void> _sendRequest() async {
    setState(() => _requesting = true);
    try {
      await CollaborationService.sendRequest(
          recipientId: widget.user.id,
          message:
              "Hi! I'd love to connect and collaborate on impactful work.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Connection request sent to ${widget.user.name}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final appError = e is AppError ? e : ErrorHandler.handleError(e);
        ErrorSnackbar.show(context, appError);
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.heading4
                          .copyWith(color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(user.name,
                            style: AppTextStyles.body1
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      _AvailabilityDot(status: user.availabilityStatus),
                    ],
                  ),
                  if (user.primaryExpertise != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.primaryExpertise!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                  if (user.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.grey400),
                        const SizedBox(width: 2),
                        Text(
                          user.location!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ],
                  if (user.skills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: user.skills
                          .take(3)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
                              ),
                              child: Text(
                                s,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        '${user.reputationPoints} rep',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey500),
                      ),
                      const Spacer(),
                      _requesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            )
                          : TextButton(
                              onPressed: _sendRequest,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Connect',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityDot extends StatelessWidget {
  final String status;
  const _AvailabilityDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'available' => AppColors.success,
      'open_to_collaborate' => AppColors.warning,
      _ => AppColors.grey300,
    };
    final tooltip = switch (status) {
      'available' => 'Available',
      'open_to_collaborate' => 'Open to Collaborate',
      _ => 'Busy',
    };
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ChangemakerCardSkeleton extends StatelessWidget {
  const _ChangemakerCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          const SkeletonLoader(width: 56, height: 56, borderRadius: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 140, height: 14),
                const SizedBox(height: AppSpacing.xs),
                const SkeletonLoader(width: 100, height: 12),
                const SizedBox(height: AppSpacing.xs),
                const SkeletonLoader(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
