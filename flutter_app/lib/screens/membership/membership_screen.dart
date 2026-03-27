import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/membership_tier_model.dart';
import '../../models/user_membership_model.dart';
import '../../services/financial_service.dart';
import '../../theme/app_colors.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  List<MembershipTier> _tiers = [];
  UserMembership? _currentMembership;
  bool _isLoading = true;
  bool _hasError = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final tiersResult = await FinancialService.getMembershipTiers();
      UserMembership? membership;
      if (_currentUserId != null) {
        membership =
            await FinancialService.getUserMembership(_currentUserId!);
      }
      if (mounted) {
        setState(() {
          _tiers = tiersResult;
          _currentMembership = membership;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildCurrentPlan(),
                      const SizedBox(height: 24),
                      const Text(
                        'Available Plans',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._tiers.map((tier) => _TierCard(
                            tier: tier,
                            isCurrentPlan:
                                _currentMembership?.tierId == tier.id ||
                                    (_currentMembership == null &&
                                        tier.slug == 'free'),
                            onUpgrade: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Stripe integration coming soon'),
                                ),
                              );
                            },
                          )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentPlan() {
    final tierName =
        _currentMembership?.tierName ?? 'Free';
    final tierSlug =
        _currentMembership?.tierSlug ?? 'free';
    final expiresAt = _currentMembership?.expiresAt;

    Color planColor;
    switch (tierSlug) {
      case 'changemaker':
        planColor = AppColors.success;
        break;
      case 'supporter':
        planColor = AppColors.primary;
        break;
      default:
        planColor = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: planColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: planColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: planColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded, color: planColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Plan',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                const SizedBox(height: 2),
                Text(
                  tierName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: planColor,
                  ),
                ),
                if (expiresAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Expires ${_formatDate(expiresAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load membership plans'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TierCard extends StatelessWidget {
  final MembershipTier tier;
  final bool isCurrentPlan;
  final VoidCallback onUpgrade;

  const _TierCard({
    required this.tier,
    required this.isCurrentPlan,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? color : Colors.grey[200]!,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tier.priceMonthly > 0)
                        Text(
                          '\$${tier.priceMonthly.toStringAsFixed(2)}/mo  '
                          '· \$${tier.priceAnnual.toStringAsFixed(2)}/yr',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        )
                      else
                        Text(
                          'Free',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (tier.description != null &&
                tier.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                tier.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            ...tier.features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isCurrentPlan) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Upgrade to ${tier.name}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
