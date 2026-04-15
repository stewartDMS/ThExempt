import 'package:flutter/material.dart';
import '../../models/skill_marketplace_model.dart';
import '../../services/skills_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../utils/error_handler.dart';

/// Phase 2 — Skills Marketplace
///
/// Two tabs: Skill Offers (people offering skills) and
/// Skill Requests (projects/people seeking skills).
class SkillsMarketplaceScreen extends StatefulWidget {
  const SkillsMarketplaceScreen({super.key});

  @override
  State<SkillsMarketplaceScreen> createState() =>
      _SkillsMarketplaceScreenState();
}

class _SkillsMarketplaceScreenState extends State<SkillsMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1A1A1A),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.brightCyan,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.brightCyan,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: 'Skill Offers'),
              Tab(text: 'Skill Requests'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _SkillOffersTab(),
              _SkillRequestsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Skill Offers Tab ──────────────────────────────────────────────────────────

class _SkillOffersTab extends StatefulWidget {
  const _SkillOffersTab();

  @override
  State<_SkillOffersTab> createState() => _SkillOffersTabState();
}

class _SkillOffersTabState extends State<_SkillOffersTab>
    with AutomaticKeepAliveClientMixin {
  List<SkillOffer> _offers = [];
  bool _isLoading = true;
  AppError? _error;
  String? _selectedCategory;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final offers = await SkillsService.getSkillOffers(
          skillCategory: _selectedCategory);
      if (mounted) {
        setState(() {
          _offers = offers;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: 5,
        itemBuilder: (_, __) => const _SkillCardSkeleton(),
      );
    }
    if (_error != null && _offers.isEmpty) {
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
    if (_offers.isEmpty) {
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
                child: const Icon(Icons.lightbulb_outline,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'No skill offers yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Be the first to offer your skills\nto the community!',
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
            top: AppSpacing.sm,
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: _offers.length,
        separatorBuilder: (_, __) => Divider(
            height: 1, color: Colors.white.withOpacity(0.06)),
        itemBuilder: (context, index) =>
            _SkillOfferCard(offer: _offers[index]),
      ),
    );
  }
}

// ── Skill Requests Tab ────────────────────────────────────────────────────────

class _SkillRequestsTab extends StatefulWidget {
  const _SkillRequestsTab();

  @override
  State<_SkillRequestsTab> createState() => _SkillRequestsTabState();
}

class _SkillRequestsTabState extends State<_SkillRequestsTab>
    with AutomaticKeepAliveClientMixin {
  List<SkillRequest> _requests = [];
  bool _isLoading = true;
  AppError? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await SkillsService.getSkillRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: 5,
        itemBuilder: (_, __) => const _SkillCardSkeleton(),
      );
    }
    if (_error != null && _requests.isEmpty) {
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
    if (_requests.isEmpty) {
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
                child: const Icon(Icons.search_outlined,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'No skill requests yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Post a skill request to find the right\ncollaborator for your project.',
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
            top: AppSpacing.sm,
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => Divider(
            height: 1, color: Colors.white.withOpacity(0.06)),
        itemBuilder: (context, index) =>
            _SkillRequestCard(request: _requests[index]),
      ),
    );
  }
}

// ── Skill Offer Card ──────────────────────────────────────────────────────────

class _SkillOfferCard extends StatelessWidget {
  final SkillOffer offer;
  const _SkillOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + location
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.electricBlue.withOpacity(0.2),
                backgroundImage: offer.userAvatarUrl != null
                    ? NetworkImage(offer.userAvatarUrl!)
                    : null,
                child: offer.userAvatarUrl == null
                    ? Text(
                        offer.userName?.isNotEmpty == true
                            ? offer.userName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.brightCyan,
                            fontWeight: FontWeight.w600),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.userName ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (offer.userLocation != null)
                      Text(offer.userLocation!,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              if (offer.availableHoursPerWeek != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.forestGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${offer.availableHoursPerWeek}h/wk',
                    style: const TextStyle(
                        color: AppColors.forestGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(offer.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(offer.description,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (offer.skillCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: offer.skillCategories
                  .take(4)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                AppColors.electricBlue.withOpacity(0.25)),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: AppColors.brightCyan, fontSize: 11)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (offer.equityPreferred || offer.rateCreditsPerHour != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (offer.rateCreditsPerHour != null) ...[
                  const Icon(Icons.token_outlined,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.rateCreditsPerHour} credits/hr',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                if (offer.equityPreferred) ...[
                  const Icon(Icons.pie_chart_outline,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  const Text(
                    'Open to equity',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Skill Request Card ────────────────────────────────────────────────────────

class _SkillRequestCard extends StatelessWidget {
  final SkillRequest request;
  const _SkillRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
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
                  color: AppColors.forestGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.forestGreen.withOpacity(0.3)),
                ),
                child: Text(
                  request.status.label,
                  style: const TextStyle(
                      color: AppColors.forestGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (request.projectTitle != null)
            Text(
              '📁 ${request.projectTitle}',
              style: const TextStyle(
                  color: AppColors.brightCyan, fontSize: 12),
            ),
          const SizedBox(height: 4),
          Text(
            request.description,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.skillCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: request.skillCategories
                  .take(4)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warmAmber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                AppColors.warmAmber.withOpacity(0.3)),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: AppColors.warmAmber, fontSize: 11)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (request.budgetCredits != null ||
              request.equityOffered != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (request.budgetCredits != null) ...[
                  const Icon(Icons.token_outlined,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '${request.budgetCredits} credits budget',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                if (request.equityOffered != null) ...[
                  const Icon(Icons.pie_chart_outline,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '${request.equityOffered!.toStringAsFixed(1)}% equity',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.electricBlue.withOpacity(0.2),
                backgroundImage: request.requesterAvatarUrl != null
                    ? NetworkImage(request.requesterAvatarUrl!)
                    : null,
                child: request.requesterAvatarUrl == null
                    ? Text(
                        request.requesterName?.isNotEmpty == true
                            ? request.requesterName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.brightCyan, fontSize: 10),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                'Posted by ${request.requesterName ?? 'Unknown'}',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SkillCardSkeleton extends StatelessWidget {
  const _SkillCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 180, height: 14),
          SizedBox(height: AppSpacing.xs),
          SkeletonLoader(width: 240, height: 12),
          SizedBox(height: AppSpacing.xs),
          SkeletonLoader(width: 140, height: 12),
        ],
      ),
    );
  }
}
