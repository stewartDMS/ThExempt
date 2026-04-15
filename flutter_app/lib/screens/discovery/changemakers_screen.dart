import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/changemakers_service.dart';
import '../../services/collaboration_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/skeleton_loader.dart';
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
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          // Dark search bar
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by skill (e.g. Design, Policy…)',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  color: Colors.white38, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips row
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
              const SizedBox(width: 8),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.electricBlue.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.electricBlue.withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.brightCyan : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      initialValue: _sort,
      color: const Color(0xFF2C2C2C),
      elevation: 8,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        setState(() => _sort = value);
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 13, color: Colors.white54),
            const SizedBox(width: 5),
            Text(
              _sort == 'recent'
                  ? 'Recent'
                  : _sort == 'activity'
                      ? 'Active'
                      : 'Top',
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down,
                size: 13, color: Colors.white38),
          ],
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'reputation',
          child: Text('Top Reputation',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        const PopupMenuItem(
          value: 'recent',
          child: Text('Recently Joined',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        const PopupMenuItem(
          value: 'activity',
          child: Text('Most Active',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
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
                    color: Colors.white),
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
      );
    }

    if (_changemakers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                child: const Icon(Icons.people_outline,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'No changemakers found',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try a different skill search or remove\nfilters to see all members.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.white54, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.brightCyan,
      child: ListView.separated(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: _changemakers.length,
        separatorBuilder: (_, __) => Divider(
            height: 1, color: Colors.white.withOpacity(0.06)),
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
        color: AppColors.charcoal,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.electricBlue.withOpacity(0.2),
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.brightCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _AvailabilityDot(status: user.availabilityStatus),
                    ],
                  ),
                  if (user.primaryExpertise != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.primaryExpertise!,
                      style: const TextStyle(
                          color: AppColors.brightCyan, fontSize: 12),
                    ),
                  ],
                  if (user.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.white38),
                        const SizedBox(width: 2),
                        Text(
                          user.location!,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (user.skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.skills
                          .take(3)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.electricBlue
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.electricBlue
                                        .withOpacity(0.25)),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                    color: AppColors.brightCyan,
                                    fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.warmAmber),
                      const SizedBox(width: 2),
                      Text(
                        '${user.reputationPoints} rep',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      const Spacer(),
                      _requesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brightCyan),
                            )
                          : TextButton(
                              onPressed: _sendRequest,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Connect',
                                style: TextStyle(
                                    color: AppColors.brightCyan,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
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
      color: AppColors.charcoal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SkeletonLoader(width: 56, height: 56, borderRadius: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 140, height: 14),
                SizedBox(height: 6),
                SkeletonLoader(width: 100, height: 12),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
