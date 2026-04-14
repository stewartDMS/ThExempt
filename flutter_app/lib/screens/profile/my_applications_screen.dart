import 'package:flutter/material.dart';
import '../../models/role_application_model.dart';
import '../../services/projects_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/time_ago.dart';

const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kDivider       = Color(0xFF2C2C2F);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<RoleApplication> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final apps = await ProjectsService.getMyApplications();
      if (mounted) {
        setState(() { _applications = apps; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMessage = e.toString(); });
      }
    }
  }

  Future<void> _withdraw(RoleApplication application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        title: const Text('Withdraw Application',
            style: TextStyle(color: _kTextPrimary)),
        content: Text(
          'Withdraw your application for "${application.roleTitle}" at "${application.projectTitle}"?',
          style: const TextStyle(color: _kTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextSecondary)),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: AppColors.deepRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProjectsService.withdrawApplication(application.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Application withdrawn'),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadApplications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.deepRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kTextSecondary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Applications',
          style: TextStyle(
              color: _kTextPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brightCyan));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppColors.deepRed),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _kTextSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadApplications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue),
              ),
            ],
          ),
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.electricBlue.withOpacity(0.3)),
                ),
                child: const Icon(Icons.description_outlined,
                    size: 40, color: AppColors.brightCyan),
              ),
              const SizedBox(height: 20),
              const Text(
                'No applications yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apply for roles in projects you\'re interested in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _kTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: AppColors.brightCyan,
      backgroundColor: _kCardBg,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _kDivider),
        itemBuilder: (context, index) {
          final app = _applications[index];
          return _ApplicationCard(
            application: app,
            onWithdraw: app.status == 'pending' ? () => _withdraw(app) : null,
          );
        },
      ),
    );
  }
}

// ── Application card ──────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final RoleApplication application;
  final VoidCallback? onWithdraw;

  const _ApplicationCard({
    required this.application,
    this.onWithdraw,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppColors.forestGreen;
      case 'rejected': return AppColors.deepRed;
      default:         return AppColors.rebellionOrange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default:         return Icons.access_time;
    }
  }

  Color _matchColor(int score) {
    if (score >= 80) return AppColors.forestGreen;
    if (score >= 50) return AppColors.warmAmber;
    return AppColors.deepRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _kCardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project title + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.projectTitle ?? 'Project',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.work_outline,
                            size: 12, color: _kTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          application.roleTitle ?? 'Role',
                          style: const TextStyle(
                              fontSize: 12, color: _kTextSecondary),
                        ),
                        if (application.roleCategory != null &&
                            application.roleCategory!.isNotEmpty) ...[
                          const Text(' · ',
                              style: TextStyle(color: _kTextSecondary)),
                          Text(
                            application.roleCategory!,
                            style: const TextStyle(
                                fontSize: 12, color: _kTextSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(application.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull),
                  border: Border.all(
                      color: _statusColor(application.status)
                          .withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(application.status),
                      size: 12,
                      color: _statusColor(application.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      application.status[0].toUpperCase() +
                          application.status.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(application.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Message preview
          Text(
            application.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, color: _kTextSecondary, height: 1.45),
          ),

          const SizedBox(height: 8),

          // Match score + date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _matchColor(application.matchScore)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                      color: _matchColor(application.matchScore)
                          .withOpacity(0.3)),
                ),
                child: Text(
                  '${application.matchScore}% match',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _matchColor(application.matchScore),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Applied ${timeAgo(application.createdAt)}',
                style: const TextStyle(
                    fontSize: 11, color: _kTextSecondary),
              ),
            ],
          ),

          // Withdraw button
          if (onWithdraw != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deepRed,
                  side: BorderSide(
                      color: AppColors.deepRed.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: const Text('Withdraw Application',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],

          // Accepted celebration
          if (application.status == 'accepted') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: AppColors.forestGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration,
                      size: 16, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You\'ve been accepted! Welcome to the team.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
