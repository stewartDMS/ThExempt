import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/changemakers_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../utils/error_handler.dart';
import '../profile/user_profile_screen.dart';

/// Phase 2 — Community Map / Location View
///
/// Groups changemakers by location and lets users explore who is nearby.
/// A full interactive map would require a mapping package; this screen
/// provides a text-based location browser with grouping until a map
/// dependency is added.
class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  List<UserProfile> _users = [];
  bool _isLoading = true;
  AppError? _error;
  String _locationSearch = '';
  final _searchController = TextEditingController();

  // Users grouped by location string
  Map<String, List<UserProfile>> get _grouped {
    final map = <String, List<UserProfile>>{};
    for (final u in _users) {
      final loc = _normaliseLocation(u.location ?? 'Unknown');
      map.putIfAbsent(loc, () => []).add(u);
    }
    return map;
  }

  String _normaliseLocation(String loc) {
    // Use city/country component: "San Francisco, CA, USA" → "San Francisco, CA"
    final parts = loc.split(',');
    if (parts.length >= 2) return '${parts[0].trim()}, ${parts[1].trim()}';
    return loc.trim();
  }

  List<MapEntry<String, List<UserProfile>>> get _filteredGrouped {
    final g = _grouped;
    if (_locationSearch.isEmpty) {
      final sorted = g.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
      return sorted;
    }
    return g.entries
        .where((e) =>
            e.key.toLowerCase().contains(_locationSearch.toLowerCase()))
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users =
          await ChangemakersService.getChangemakersWithLocation();
      if (mounted) {
        setState(() {
          _users = users;
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
        ErrorSnackbar.show(context, appError, onRetry: _loadData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 16, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    '${_users.length} changemakers across '
                    '${_grouped.length} locations',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          // Location search
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _locationSearch = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by city or country…',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.location_searching,
                  color: Colors.white38, size: 20),
              suffixIcon: _locationSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _locationSearch = '');
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
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: 5,
        itemBuilder: (_, __) => _buildLocationSkeleton(),
      );
    }

    if (_users.isEmpty) {
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
                child: const Icon(Icons.map_outlined,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'No location data yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update your profile with your location\nto appear on the community map!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.white54, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _filteredGrouped;

    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No locations matching "$_locationSearch"',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.brightCyan,
      child: ListView.builder(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final entry = groups[index];
          return _LocationGroup(
            location: entry.key,
            users: entry.value,
          );
        },
      ),
    );
  }

  Widget _buildLocationSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 120, height: 14),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: SkeletonLoader(width: 44, height: 44, borderRadius: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Location Group ────────────────────────────────────────────────────────────

class _LocationGroup extends StatelessWidget {
  final String location;
  final List<UserProfile> users;

  const _LocationGroup({required this.location, required this.users});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location header
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 14, color: AppColors.brightCyan),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.electricBlue.withOpacity(0.3)),
                ),
                child: Text(
                  '${users.length}',
                  style: const TextStyle(
                      color: AppColors.brightCyan, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Avatar row – show up to 5 avatars
          Row(
            children: [
              ...users.take(5).map(
                    (u) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: u.id),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: u.name,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppColors.electricBlue.withOpacity(0.2),
                            backgroundImage: u.avatarUrl != null
                                ? NetworkImage(u.avatarUrl!)
                                : null,
                            child: u.avatarUrl == null
                                ? Text(
                                    u.name.isNotEmpty
                                        ? u.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: AppColors.brightCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              if (users.length > 5)
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  child: Text(
                    '+${users.length - 5}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
        ],
      ),
    );
  }
}
