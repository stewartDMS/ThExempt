import 'package:flutter/material.dart';
import '../../models/skill_marketplace_model.dart';
import '../../services/skills_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/empty_state.dart';
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
          color: AppColors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
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
      return ErrorStateWidget(error: _error!, onRetry: _loadData);
    }
    if (_offers.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No skill offers yet',
        subtitle: 'Be the first to offer your skills to the community!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: _offers.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider),
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
      return ErrorStateWidget(error: _error!, onRetry: _loadData);
    }
    if (_requests.isEmpty) {
      return const EmptyState(
        icon: Icons.search_outlined,
        title: 'No skill requests yet',
        subtitle:
            'Post a skill request to find the right collaborator for your project.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.bottomNavWithFabPadding),
        itemCount: _requests.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + location
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: offer.userAvatarUrl != null
                    ? NetworkImage(offer.userAvatarUrl!)
                    : null,
                child: offer.userAvatarUrl == null
                    ? Text(
                        offer.userName?.isNotEmpty == true
                            ? offer.userName![0].toUpperCase()
                            : '?',
                        style: AppTextStyles.body2
                            .copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.userName ?? 'Unknown',
                        style: AppTextStyles.body2
                            .copyWith(fontWeight: FontWeight.w600)),
                    if (offer.userLocation != null)
                      Text(offer.userLocation!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ),
              if (offer.availableHoursPerWeek != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${offer.availableHoursPerWeek}h/wk',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(offer.title,
              style:
                  AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(offer.description,
              style:
                  AppTextStyles.body2.copyWith(color: AppColors.grey600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (offer.skillCategories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: offer.skillCategories
                  .take(4)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(s,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (offer.equityPreferred || offer.rateCreditsPerHour != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (offer.rateCreditsPerHour != null) ...[
                  const Icon(Icons.token_outlined,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.rateCreditsPerHour} credits/hr',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (offer.equityPreferred) ...[
                  const Icon(Icons.pie_chart_outline,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    'Open to equity',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grey500),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: AppTextStyles.body1
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  request.status.label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (request.projectTitle != null)
            Text(
              '📁 ${request.projectTitle}',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          const SizedBox(height: 4),
          Text(
            request.description,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.skillCategories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: request.skillCategories
                  .take(4)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(s,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.warning)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (request.budgetCredits != null ||
              request.equityOffered != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (request.budgetCredits != null) ...[
                  const Icon(Icons.token_outlined,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    '${request.budgetCredits} credits budget',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (request.equityOffered != null) ...[
                  const Icon(Icons.pie_chart_outline,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    '${request.equityOffered!.toStringAsFixed(1)}% equity',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grey500),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: request.requesterAvatarUrl != null
                    ? NetworkImage(request.requesterAvatarUrl!)
                    : null,
                child: request.requesterAvatarUrl == null
                    ? Text(
                        request.requesterName?.isNotEmpty == true
                            ? request.requesterName![0].toUpperCase()
                            : '?',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary, fontSize: 10),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Posted by ${request.requesterName ?? 'Unknown'}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.grey500),
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
