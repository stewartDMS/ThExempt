import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/project_investment_model.dart';
import '../../../services/financial_service.dart';
import '../../../utils/time_ago.dart';
import '../../../theme/app_colors.dart';

class ProjectInvestmentTab extends StatefulWidget {
  final Project project;
  final String? currentUserId;
  final void Function(Project)? onProjectUpdated;

  const ProjectInvestmentTab({
    super.key,
    required this.project,
    this.currentUserId,
    this.onProjectUpdated,
  });

  @override
  State<ProjectInvestmentTab> createState() => _ProjectInvestmentTabState();
}

class _ProjectInvestmentTabState extends State<ProjectInvestmentTab> {
  List<ProjectInvestment> _investments = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _investLoading = false;

  late int _totalInvested;
  late int _investorCount;

  @override
  void initState() {
    super.initState();
    _totalInvested = widget.project.totalInvested;
    _investorCount = widget.project.investorCount;
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final investments =
          await FinancialService.getProjectInvestments(widget.project.id);
      if (mounted) {
        setState(() {
          _investments = investments;
          _totalInvested =
              investments.fold(0, (sum, i) => sum + i.creditsAmount);
          _investorCount = investments.length;
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

  Future<void> _showInvestDialog() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to invest in this project')),
      );
      return;
    }
    if (widget.currentUserId == widget.project.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot invest in your own project')),
      );
      return;
    }

    final creditsController = TextEditingController();
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invest Credits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: creditsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Credits (1-999)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Invest'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final raw = int.tryParse(creditsController.text.trim());
    if (raw == null || raw < 1 || raw > 999) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount between 1 and 999')),
        );
      }
      return;
    }

    setState(() => _investLoading = true);
    try {
      await FinancialService.investInProject(
        widget.project.id,
        raw,
        message: messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
      );
      await _loadInvestments();
      widget.onProjectUpdated?.call(
        widget.project.copyWith(
          totalInvested: _totalInvested,
          investorCount: _investorCount,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _investLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadInvestments,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildStatsHeader()),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text('Failed to load investments'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadInvestments,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_investments.isEmpty)
            const SliverFillRemaining(
              child: _EmptyInvestments(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) =>
                    _InvestmentCard(investment: _investments[i]),
                childCount: _investments.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final isOwner = widget.currentUserId == widget.project.ownerId;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.savings_outlined,
                  label: 'Total Invested',
                  value: '$_totalInvested credits',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.people_outline,
                  label: 'Investors',
                  value: '$_investorCount',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (!isOwner) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _investLoading ? null : _showInvestDialog,
                icon: _investLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.trending_up_outlined),
                label: const Text('Invest Credits'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (_investments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Investors',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final ProjectInvestment investment;

  const _InvestmentCard({required this.investment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage:
                investment.userAvatarUrl != null &&
                        investment.userAvatarUrl!.isNotEmpty
                    ? NetworkImage(investment.userAvatarUrl!)
                    : null,
            backgroundColor: AppColors.success.withOpacity(0.15),
            child: investment.userAvatarUrl == null ||
                    investment.userAvatarUrl!.isEmpty
                ? Text(
                    investment.userName.isNotEmpty
                        ? investment.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      investment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeAgo(investment.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '${investment.creditsAmount} credits',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (investment.message != null &&
                    investment.message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    investment.message!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvestments extends StatelessWidget {
  const _EmptyInvestments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No investments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to invest in this project!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
