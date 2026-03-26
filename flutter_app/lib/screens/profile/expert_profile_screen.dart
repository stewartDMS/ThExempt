import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/expert_badge_model.dart';
import '../../services/expert_badges_service.dart';
import '../../theme/app_colors.dart';

/// Phase 1 — Expert Badges & Trust System screen.
///
/// Displays a user's earned badges, trust score, expertise areas,
/// and (for the current user) an interface to add or remove expertise.
class ExpertProfileScreen extends StatefulWidget {
  /// The user whose expertise to display. If null, shows the current user.
  final String? userId;

  /// Optional display name for the app bar title.
  final String? userName;

  const ExpertProfileScreen({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<ExpertProfileScreen> createState() => _ExpertProfileScreenState();
}

class _ExpertProfileScreenState extends State<ExpertProfileScreen> {
  List<UserExpertise> _expertise = [];
  UserBadges? _badges;
  bool _loading = true;

  late final String _targetUserId;
  bool get _isOwnProfile =>
      _targetUserId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _targetUserId = widget.userId ??
        Supabase.instance.client.auth.currentUser?.id ??
        '';
    _load();
  }

  Future<void> _load() async {
    if (_targetUserId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ExpertBadgesService.getExpertise(_targetUserId),
        ExpertBadgesService.getBadges(_targetUserId),
      ]);
      if (mounted) {
        setState(() {
          _expertise = results[0] as List<UserExpertise>;
          _badges = results[1] as UserBadges;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddExpertiseDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddExpertiseDialog(
        onAdded: (expertise) {
          setState(() => _expertise.insert(0, expertise));
          // Reload badges to pick up any newly earned ones
          ExpertBadgesService.getBadges(_targetUserId).then((b) {
            if (mounted) setState(() => _badges = b);
          });
        },
      ),
    );
  }

  Future<void> _removeExpertise(UserExpertise e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Expertise'),
        content: Text('Remove "${e.area}" from your expertise areas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ExpertBadgesService.removeExpertise(e.id);
      setState(() => _expertise.remove(e));
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $err'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyExpertise(UserExpertise e) async {
    try {
      await ExpertBadgesService.verifyExpertise(expertiseId: e.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endorsement submitted!'),
          backgroundColor: AppColors.success,
        ),
      );
      _load(); // refresh to reflect updated verification count
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not endorse: $err'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName != null
            ? '${widget.userName}\'s Expertise'
            : 'My Expertise & Badges'),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Expertise Area',
              onPressed: _showAddExpertiseDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _targetUserId.isEmpty
              ? const Center(child: Text('Please sign in to view expertise'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // ── Trust score card ─────────────────────────────
                      if (_badges != null) _buildTrustCard(),

                      // ── Badges section ───────────────────────────────
                      if (_badges != null && _badges!.badges.isNotEmpty)
                        _buildBadgesSection(),

                      // ── Expertise areas ──────────────────────────────
                      _buildExpertiseSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTrustCard() {
    final score = _badges!.trustScore;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trust Score',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$score',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _trustLevel(score),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          _TrustMeter(score: score),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earned Badges',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _badges!.badges.map((b) => _BadgeChip(badge: b)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Text(
                'Expertise Areas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const Spacer(),
              if (_isOwnProfile)
                TextButton.icon(
                  onPressed: _showAddExpertiseDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        if (_expertise.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              _isOwnProfile
                  ? 'No expertise areas added yet. Tap "Add" to declare your expertise.'
                  : 'This user has not added expertise areas yet.',
              style: const TextStyle(fontSize: 14, color: AppColors.grey400),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expertise.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _ExpertiseTile(
              expertise: _expertise[i],
              isOwnProfile: _isOwnProfile,
              onRemove: _isOwnProfile ? () => _removeExpertise(_expertise[i]) : null,
              onVerify: !_isOwnProfile ? () => _verifyExpertise(_expertise[i]) : null,
            ),
          ),
      ],
    );
  }

  String _trustLevel(int score) {
    if (score >= 1000) return 'Master Changemaker';
    if (score >= 500) return 'Expert Contributor';
    if (score >= 100) return 'Active Contributor';
    return 'Community Member';
  }
}

// ── Trust meter ───────────────────────────────────────────────────────────

class _TrustMeter extends StatelessWidget {
  final int score;

  const _TrustMeter({required this.score});

  @override
  Widget build(BuildContext context) {
    final progress = (score / 1000).clamp(0.0, 1.0);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
          const Icon(Icons.shield_outlined,
              size: 28, color: AppColors.white),
        ],
      ),
    );
  }
}

// ── Badge chip ────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final String badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final data = _badgeData(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            badge,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeData _badgeData(String badge) {
    switch (badge) {
      case 'Contributor':
        return _BadgeData('⭐', AppColors.warning);
      case 'Expert':
        return _BadgeData('🏅', AppColors.primary);
      case 'Master':
        return _BadgeData('👑', const Color(0xFF9C27B0));
      case 'Verified Expert':
        return _BadgeData('✅', AppColors.success);
      case 'Community Pillar':
        return _BadgeData('🏛️', const Color(0xFF1565C0));
      case 'Movement Builder':
        return _BadgeData('🚀', AppColors.error);
      case 'Resource Contributor':
        return _BadgeData('📚', const Color(0xFF3F51B5));
      default:
        return _BadgeData('🎖️', AppColors.grey500);
    }
  }
}

class _BadgeData {
  final String emoji;
  final Color color;
  const _BadgeData(this.emoji, this.color);
}

// ── Expertise tile ─────────────────────────────────────────────────────────

class _ExpertiseTile extends StatelessWidget {
  final UserExpertise expertise;
  final bool isOwnProfile;
  final VoidCallback? onRemove;
  final VoidCallback? onVerify;

  const _ExpertiseTile({
    required this.expertise,
    required this.isOwnProfile,
    this.onRemove,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(expertise.level);
    final verificationCount = expertise.verifications.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.psychology_outlined,
                  size: 22, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (expertise.isPrimary) ...[
                      const Icon(Icons.star, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        expertise.area,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: levelColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: levelColor.withAlpha(60)),
                      ),
                      child: Text(
                        expertise.level.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: levelColor,
                        ),
                      ),
                    ),
                    if (verificationCount > 0) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified_outlined,
                          size: 12, color: AppColors.success),
                      const SizedBox(width: 2),
                      Text(
                        '$verificationCount endorsement${verificationCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey500),
                      ),
                    ],
                  ],
                ),
                if (expertise.evidenceUrl != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    expertise.evidenceUrl!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onVerify != null)
            TextButton(
              onPressed: onVerify,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Endorse'),
            ),
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 16, color: AppColors.grey400),
              ),
            ),
        ],
      ),
    );
  }

  Color _levelColor(ExpertiseLevel level) {
    switch (level) {
      case ExpertiseLevel.selfDeclared:
        return AppColors.grey500;
      case ExpertiseLevel.communityVerified:
        return AppColors.warning;
      case ExpertiseLevel.expertVerified:
        return AppColors.primary;
      case ExpertiseLevel.platformVerified:
        return AppColors.success;
    }
  }
}

// ── Add expertise dialog ──────────────────────────────────────────────────

class _AddExpertiseDialog extends StatefulWidget {
  final ValueChanged<UserExpertise> onAdded;

  const _AddExpertiseDialog({required this.onAdded});

  @override
  State<_AddExpertiseDialog> createState() => _AddExpertiseDialogState();
}

class _AddExpertiseDialogState extends State<_AddExpertiseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _evidenceController = TextEditingController();
  bool _isPrimary = false;
  bool _submitting = false;

  static const _suggestedAreas = [
    'Climate Policy', 'Renewable Energy', 'Democracy Reform',
    'Healthcare Access', 'Education Equity', 'Housing Justice',
    'Criminal Justice Reform', 'Immigration Policy', 'Mental Health',
    'Community Organizing', 'Open Source', 'Digital Rights',
    'Economic Justice', 'Labor Rights', 'Racial Equity',
  ];

  @override
  void dispose() {
    _areaController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final expertise = await ExpertBadgesService.addExpertise(
        area: _areaController.text.trim(),
        evidenceUrl: _evidenceController.text.trim().isEmpty
            ? null
            : _evidenceController.text.trim(),
        isPrimary: _isPrimary,
      );
      widget.onAdded(expertise);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expertise Area'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Expertise Area *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Climate Policy, Healthcare Access',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Area is required'
                      : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Suggestions:',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _suggestedAreas.map((area) {
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _areaController.text = area),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Text(area,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _evidenceController,
                  decoration: const InputDecoration(
                    labelText: 'Evidence URL (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Link to credential, publication, portfolio…',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: _isPrimary,
                      onChanged: (v) => setState(() => _isPrimary = v),
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Set as primary expertise',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.grey600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
