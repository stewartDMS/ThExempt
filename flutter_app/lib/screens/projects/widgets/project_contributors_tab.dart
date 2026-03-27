import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../models/project_contribution_model.dart';
import '../../../services/financial_service.dart';
import '../../../utils/time_ago.dart';
import '../../../theme/app_colors.dart';

class ProjectContributorsTab extends StatefulWidget {
  final Project project;
  final String? currentUserId;
  final bool isOwner;

  const ProjectContributorsTab({
    super.key,
    required this.project,
    this.currentUserId,
    required this.isOwner,
  });

  @override
  State<ProjectContributorsTab> createState() => _ProjectContributorsTabState();
}

class _ProjectContributorsTabState extends State<ProjectContributorsTab> {
  List<ProjectContribution> _contributions = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _addLoading = false;

  static const _types = ['credits', 'skills', 'time', 'other'];

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results =
          await FinancialService.getProjectContributions(widget.project.id);
      if (mounted) {
        setState(() {
          _contributions = results;
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

  Future<void> _showAddContributionDialog() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to add a contribution')),
      );
      return;
    }

    String selectedType = 'skills';
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Contribution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _types.map((t) {
                  final selected = t == selectedType;
                  return ChoiceChip(
                    label: Text(_typeLabel(t)),
                    selected: selected,
                    onSelected: (_) => setDialogState(() => selectedType = t),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (optional)',
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description is required')),
        );
      }
      return;
    }

    final amount = int.tryParse(amountController.text.trim()) ?? 0;

    setState(() => _addLoading = true);
    try {
      await FinancialService.addContribution(
        widget.project.id,
        selectedType,
        description,
        amount: amount,
      );
      await _loadContributions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution added!')),
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
      if (mounted) setState(() => _addLoading = false);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'credits':
        return '💰 Credits';
      case 'skills':
        return '🛠 Skills';
      case 'time':
        return '⏰ Time';
      default:
        return '📦 Other';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'credits':
        return AppColors.success;
      case 'skills':
        return AppColors.primary;
      case 'time':
        return AppColors.warning;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadContributions,
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text('Failed to load contributions'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadContributions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_contributions.isEmpty)
            const SliverFillRemaining(
              child: _EmptyContributions(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _ContributionCard(
                  contribution: _contributions[i],
                  typeColor: _typeColor(_contributions[i].contributionType),
                  typeLabel: _typeLabel(_contributions[i].contributionType),
                ),
                childCount: _contributions.length,
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
              const Icon(Icons.volunteer_activism_outlined,
                  size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${_contributions.length} Contribution${_contributions.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.currentUserId != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addLoading ? null : _showAddContributionDialog,
                icon: _addLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_outlined),
                label: const Text('Add Contribution'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (_contributions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
          ],
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final ProjectContribution contribution;
  final Color typeColor;
  final String typeLabel;

  const _ContributionCard({
    required this.contribution,
    required this.typeColor,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: contribution.userAvatarUrl != null &&
                    contribution.userAvatarUrl!.isNotEmpty
                ? NetworkImage(contribution.userAvatarUrl!)
                : null,
            backgroundColor: typeColor.withOpacity(0.15),
            child: contribution.userAvatarUrl == null ||
                    contribution.userAvatarUrl!.isEmpty
                ? Text(
                    contribution.userName.isNotEmpty
                        ? contribution.userName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
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
                      contribution.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeAgo(contribution.createdAt),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  contribution.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                if (contribution.amount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${contribution.amount} units',
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
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

class _EmptyContributions extends StatelessWidget {
  const _EmptyContributions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No contributions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to contribute to this project!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
