import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/project_model.dart';
import '../../../models/project_equity_model.dart';
import '../../../services/financial_service.dart';
import '../../../utils/time_ago.dart';
import '../../../theme/app_colors.dart';

const double _kMinEquityPct = 0.01;
const double _kMaxEquityPct = 100.0;

class ProjectEquityTab extends StatefulWidget {
  final Project project;
  final bool isOwner;

  const ProjectEquityTab({
    super.key,
    required this.project,
    required this.isOwner,
  });

  @override
  State<ProjectEquityTab> createState() => _ProjectEquityTabState();
}

class _ProjectEquityTabState extends State<ProjectEquityTab> {
  List<ProjectEquity> _equity = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _grantLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEquity();
  }

  Future<void> _loadEquity() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results =
          await FinancialService.getProjectEquity(widget.project.id);
      if (mounted) {
        setState(() {
          _equity = results;
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

  double get _totalEquityGranted =>
      _equity.fold(0.0, (sum, e) => sum + e.equityPercentage);

  Future<void> _showGrantEquityDialog() async {
    final userIdController = TextEditingController();
    final percentageController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grant Equity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter the recipient\'s user ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: percentageController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Equity % ($_kMinEquityPct–$_kMaxEquityPct)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_totalEquityGranted > 0)
              Text(
                'Already granted: ${_totalEquityGranted.toStringAsFixed(2)}%',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            child: const Text('Grant'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = userIdController.text.trim();
    final percentage =
        double.tryParse(percentageController.text.trim());

    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID is required')),
        );
      }
      return;
    }

    if (percentage == null || percentage < _kMinEquityPct || percentage > _kMaxEquityPct) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enter a valid percentage between $_kMinEquityPct and $_kMaxEquityPct')),
        );
      }
      return;
    }

    if (_totalEquityGranted + percentage > _kMaxEquityPct) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Warning: total equity would exceed 100% '
              '(${(_totalEquityGranted + percentage).toStringAsFixed(2)}%)',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() => _grantLoading = true);
    try {
      await _grantEquityDirect(
        userId: userId,
        percentage: percentage,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );
      await _loadEquity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equity granted!')),
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
      if (mounted) setState(() => _grantLoading = false);
    }
  }

  Future<void> _grantEquityDirect({
    required String userId,
    required double percentage,
    String? description,
  }) async {
    await Supabase.instance.client
        .from('project_equity')
        .upsert(
          {
            'project_id': widget.project.id,
            'user_id': userId,
            'equity_percentage': percentage,
            if (description != null) 'description': description,
          },
          onConflict: 'project_id,user_id',
        )
        .timeout(const Duration(seconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadEquity,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
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
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text('Failed to load equity'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadEquity,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_equity.isEmpty)
            const SliverFillRemaining(
              child: _EmptyEquity(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _EquityCard(equity: _equity[i]),
                childCount: _equity.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline,
                  size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Equity Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_equity.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_totalEquityGranted.toStringAsFixed(1)}% granted',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.isOwner) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _grantLoading ? null : _showGrantEquityDialog,
                icon: _grantLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_outlined),
                label: const Text('Grant Equity'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (_equity.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Equity holders',
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

class _EquityCard extends StatelessWidget {
  final ProjectEquity equity;

  const _EquityCard({required this.equity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: equity.userAvatarUrl != null &&
                    equity.userAvatarUrl!.isNotEmpty
                ? NetworkImage(equity.userAvatarUrl!)
                : null,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: equity.userAvatarUrl == null ||
                    equity.userAvatarUrl!.isEmpty
                ? Text(
                    equity.userName.isNotEmpty
                        ? equity.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                      equity.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${equity.equityPercentage.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Granted ${timeAgo(equity.grantedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (equity.description != null &&
                    equity.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    equity.description!,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey[700]),
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

class _EmptyEquity extends StatelessWidget {
  const _EmptyEquity();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No equity granted yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Project owners can grant equity to contributors.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
