import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/expert_badge_model.dart';
import '../../services/expert_badges_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kDivider       = Color(0xFF2C2C2F);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

/// Phase 1 — Expert Badges & Trust System screen (dark theme).
class ExpertProfileScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const ExpertProfileScreen({super.key, this.userId, this.userName});

  @override
  State<ExpertProfileScreen> createState() =>
      _ExpertProfileScreenState();
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
          _badges    = results[1] as UserBadges;
          _loading   = false;
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
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        title: const Text('Remove Expertise',
            style: TextStyle(color: _kTextPrimary)),
        content: Text(
          'Remove "${e.area}" from your expertise areas?',
          style: const TextStyle(color: _kTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.deepRed),
            child: const Text('Remove',
                style: TextStyle(fontWeight: FontWeight.w700)),
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
              backgroundColor: AppColors.deepRed),
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
          backgroundColor: AppColors.forestGreen,
        ),
      );
      _load();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not endorse: $err'),
              backgroundColor: AppColors.deepRed),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
        title: Text(
          widget.userName != null
              ? '${widget.userName}\'s Expertise'
              : 'My Expertise & Badges',
          style: const TextStyle(
              color: _kTextPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.brightCyan, size: 22),
              tooltip: 'Add Expertise Area',
              onPressed: _showAddExpertiseDialog,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brightCyan))
          : _targetUserId.isEmpty
              ? const Center(
                  child: Text('Please sign in to view expertise',
                      style: TextStyle(color: _kTextSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brightCyan,
                  backgroundColor: _kCardBg,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 40),
                    children: [
                      if (_badges != null) _buildTrustCard(),
                      if (_badges != null && _badges!.badges.isNotEmpty)
                        _buildBadgesSection(),
                      _buildExpertiseSection(),
                    ],
                  ),
                ),
    );
  }

  // ── Trust card ────────────────────────────────────────────────────────────

  Widget _buildTrustCard() {
    final score = _badges!.trustScore;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B2A),
            AppColors.electricBlue.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.electricBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _trustLevel(score),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65), fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          _TrustMeter(score: score),
        ],
      ),
    );
  }

  // ── Badges section ─────────────────────────────────────────────────────────

  Widget _buildBadgesSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech_outlined,
                  size: 18, color: AppColors.warmAmber),
              SizedBox(width: 8),
              Text(
                'Earned Badges',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _badges!.badges
                .map((b) => _BadgeChip(badge: b))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Expertise section ──────────────────────────────────────────────────────

  Widget _buildExpertiseSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    size: 18, color: AppColors.brightCyan),
                const SizedBox(width: 8),
                const Text(
                  'Expertise Areas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                const Spacer(),
                if (_isOwnProfile)
                  TextButton.icon(
                    onPressed: _showAddExpertiseDialog,
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brightCyan,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          if (_expertise.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _isOwnProfile
                    ? 'No expertise areas added yet. Tap "Add" to declare your expertise.'
                    : 'This user has not added expertise areas yet.',
                style: const TextStyle(
                    fontSize: 13, color: _kTextSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expertise.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _kDivider),
              itemBuilder: (_, i) => _ExpertiseTile(
                expertise: _expertise[i],
                isOwnProfile: _isOwnProfile,
                onRemove: _isOwnProfile
                    ? () => _removeExpertise(_expertise[i])
                    : null,
                onVerify: !_isOwnProfile
                    ? () => _verifyExpertise(_expertise[i])
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  String _trustLevel(int score) {
    if (score >= 1000) return 'Master Changemaker';
    if (score >= 500)  return 'Expert Contributor';
    if (score >= 100)  return 'Active Contributor';
    return 'Community Member';
  }
}

// ── Trust meter ───────────────────────────────────────────────────────────────

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
            backgroundColor: Colors.white12,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.brightCyan),
          ),
          const Icon(Icons.shield_outlined,
              size: 28, color: Colors.white),
        ],
      ),
    );
  }
}

// ── Badge chip ────────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final String badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final data = _badgeData(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: data.color.withOpacity(0.35)),
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
              fontWeight: FontWeight.w700,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeData _badgeData(String badge) {
    switch (badge) {
      case 'Contributor':       return _BadgeData('⭐', AppColors.warmAmber);
      case 'Expert':            return _BadgeData('🏅', AppColors.electricBlue);
      case 'Master':            return _BadgeData('👑', const Color(0xFF9C27B0));
      case 'Verified Expert':   return _BadgeData('✅', AppColors.forestGreen);
      case 'Community Pillar':  return _BadgeData('🏛️', const Color(0xFF1565C0));
      case 'Movement Builder':  return _BadgeData('🚀', AppColors.deepRed);
      case 'Resource Contributor':
                                return _BadgeData('📚', const Color(0xFF3F51B5));
      default:                  return _BadgeData('🎖️', AppColors.grey500);
    }
  }
}

class _BadgeData {
  final String emoji;
  final Color color;
  const _BadgeData(this.emoji, this.color);
}

// ── Expertise tile ────────────────────────────────────────────────────────────

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

  Color _levelColor(ExpertiseLevel level) {
    switch (level) {
      case ExpertiseLevel.selfDeclared:       return AppColors.grey500;
      case ExpertiseLevel.communityVerified:  return AppColors.warmAmber;
      case ExpertiseLevel.expertVerified:     return AppColors.electricBlue;
      case ExpertiseLevel.platformVerified:   return AppColors.forestGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor       = _levelColor(expertise.level);
    final verificationCount = expertise.verifications.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.electricBlue.withOpacity(0.25)),
            ),
            child: const Center(
              child: Icon(Icons.psychology_outlined,
                  size: 22, color: AppColors.brightCyan),
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
                      const Icon(Icons.star,
                          size: 12, color: AppColors.warmAmber),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        expertise.area,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
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
                        color: levelColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: levelColor.withOpacity(0.35)),
                      ),
                      child: Text(
                        expertise.level.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: levelColor,
                        ),
                      ),
                    ),
                    if (verificationCount > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_outlined,
                          size: 12, color: AppColors.forestGreen),
                      const SizedBox(width: 3),
                      Text(
                        '$verificationCount endorsement${verificationCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSecondary),
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
                      color: AppColors.brightCyan,
                      decoration: TextDecoration.underline,
                    ),
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
                foregroundColor: AppColors.forestGreen,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
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
                child: Icon(Icons.close,
                    size: 16, color: _kTextSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Add Expertise Dialog ──────────────────────────────────────────────────────

class _AddExpertiseDialog extends StatefulWidget {
  final void Function(UserExpertise) onAdded;

  const _AddExpertiseDialog({required this.onAdded});

  @override
  State<_AddExpertiseDialog> createState() =>
      _AddExpertiseDialogState();
}

class _AddExpertiseDialogState extends State<_AddExpertiseDialog> {
  final _areaController     = TextEditingController();
  final _evidenceController = TextEditingController();
  bool _isPrimary = false;
  bool _saving    = false;

  static const _areas = [
    'Software Engineering', 'Data Science', 'UX/UI Design',
    'Product Management', 'Digital Marketing', 'Finance',
    'Legal', 'Operations', 'Healthcare', 'Education',
    'Environmental Science', 'Community Organizing', 'Journalism',
  ];

  @override
  void dispose() {
    _areaController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final area = _areaController.text.trim();
    if (area.isEmpty) return;
    setState(() => _saving = true);
    try {
      final expertise = await ExpertBadgesService.addExpertise(
        area: area,
        isPrimary: _isPrimary,
        evidenceUrl: _evidenceController.text.trim().isNotEmpty
            ? _evidenceController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onAdded(expertise);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.deepRed),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kCardBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      title: const Text('Add Expertise Area',
          style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area suggestions
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _areas.map((area) {
                return GestureDetector(
                  onTap: () =>
                      _areaController.text = area,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                          color: AppColors.electricBlue.withOpacity(0.25)),
                    ),
                    child: Text(
                      area,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.brightCyan),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _areaController,
              style: const TextStyle(color: _kTextPrimary, fontSize: 13),
              decoration: _inputDecoration('Expertise Area *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _evidenceController,
              style: const TextStyle(color: _kTextPrimary, fontSize: 13),
              decoration:
                  _inputDecoration('Evidence URL (optional)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _isPrimary,
                  onChanged: (v) =>
                      setState(() => _isPrimary = v ?? false),
                  activeColor: AppColors.brightCyan,
                  checkColor: _kBg,
                  side:
                      const BorderSide(color: _kTextSecondary),
                ),
                const Text('Set as primary expertise',
                    style:
                        TextStyle(color: _kTextSecondary, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: _kTextSecondary)),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          style: TextButton.styleFrom(
              foregroundColor: AppColors.brightCyan),
          child: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.brightCyan),
                )
              : const Text('Add',
                  style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF252528),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(
            color: AppColors.brightCyan, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
    );
  }
}
