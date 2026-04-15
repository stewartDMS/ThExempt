import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/discussion_model.dart';
import '../../services/discussion_resources_service.dart';
import '../../theme/app_colors.dart';
import '../projects/create_project_screen.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kCardBg        = Color(0xFF1C1C1E);
const _kInputFill     = Color(0xFF252528);
const _kBorder        = Color(0xFF3A3A3C);
const _kDivider       = Color(0xFF2C2C2F);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

/// Phase 1 — Problem → Solution → Project pipeline panel.
///
/// Displays the current stage as a stepper, upvote/downvote controls,
/// and (for the discussion author) a button to advance the stage.
class DiscussionPipelinePanel extends StatefulWidget {
  final Discussion discussion;

  /// Called after the stage or vote count changes so the parent can refresh.
  final ValueChanged<Discussion>? onUpdated;

  const DiscussionPipelinePanel({
    super.key,
    required this.discussion,
    this.onUpdated,
  });

  @override
  State<DiscussionPipelinePanel> createState() =>
      _DiscussionPipelinePanelState();
}

class _DiscussionPipelinePanelState extends State<DiscussionPipelinePanel> {
  late Discussion _discussion;
  bool _votingInProgress = false;
  bool _advancingStage = false;

  // Current user's vote: 1, -1, or 0
  int _userVote = 0;

  @override
  void initState() {
    super.initState();
    _discussion = widget.discussion;
    _loadUserVote();
  }

  @override
  void didUpdateWidget(DiscussionPipelinePanel old) {
    super.didUpdateWidget(old);
    if (old.discussion.id != widget.discussion.id) {
      _discussion = widget.discussion;
      _loadUserVote();
    }
  }

  Future<void> _loadUserVote() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('discussion_votes')
          .select('value')
          .eq('discussion_id', _discussion.id)
          .eq('user_id', userId);
      if (mounted && rows.isNotEmpty) {
        setState(() => _userVote = (rows.first['value'] as num).toInt());
      }
    } catch (_) {}
  }

  Future<void> _vote(int value) async {
    if (_votingInProgress) return;
    setState(() => _votingInProgress = true);

    try {
      if (_userVote == value) {
        // Retract existing vote
        await DiscussionResourcesService.retractVote(_discussion.id);
        setState(() {
          _discussion = _discussion.copyWith(
            votesCount: _discussion.votesCount - value,
          );
          _userVote = 0;
        });
      } else {
        // Cast or switch vote
        final delta = value - _userVote; // e.g. switching from -1 to +1 = +2
        await DiscussionResourcesService.castVote(_discussion.id, value);
        setState(() {
          _discussion = _discussion.copyWith(
            votesCount: _discussion.votesCount + delta,
          );
          _userVote = value;
        });
      }
      widget.onUpdated?.call(_discussion);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not cast vote: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _votingInProgress = false);
    }
  }

  Future<void> _advanceStage() async {
    final nextStage = _nextStage(_discussion.stage);
    if (nextStage == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Advance Stage'),
        content: Text(
          'Move this discussion from "${_discussion.stage.label}" to '
          '"${nextStage.label}"?\n\n'
          '${nextStage.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Advance'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _advancingStage = true);
    try {
      await DiscussionResourcesService.advancePipelineStage(
        _discussion.id,
        nextStage.value,
      );
      setState(() {
        _discussion = _discussion.copyWith(stage: nextStage);
      });
      widget.onUpdated?.call(_discussion);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not advance stage: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _advancingStage = false);
    }
  }

  Future<void> _launchProjectFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          initialTitle: _discussion.title,
          initialDescription: _discussion.content,
          sourceDiscussionId: _discussion.id,
        ),
      ),
    );
  }

  static DiscussionStage? _nextStage(DiscussionStage current) {
    switch (current) {
      case DiscussionStage.problem:
        return DiscussionStage.solution;
      case DiscussionStage.solution:
        return DiscussionStage.projectProposal;
      case DiscussionStage.projectProposal:
        return null; // Advancing to projectLinked is done via "Create Project from This"
      case DiscussionStage.projectLinked:
        return null;
    }
  }

  bool get _isAuthor =>
      Supabase.instance.client.auth.currentUser?.id == _discussion.authorId;

  bool get _isAuthenticated =>
      Supabase.instance.client.auth.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.route_outlined,
                    size: 18, color: AppColors.brightCyan),
                const SizedBox(width: 8),
                const Text(
                  'Pipeline Progress',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                const Spacer(),
                _StagePill(stage: _discussion.stage),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Stage stepper ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StageStepper(currentStage: _discussion.stage),
          ),

          const SizedBox(height: 16),

          const Divider(height: 1, color: _kDivider),

          // ── Voting row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Text(
                  'Community votes:',
                  style: TextStyle(
                      fontSize: 13, color: _kTextSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_discussion.votesCount >= 0 ? '+' : ''}${_discussion.votesCount}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _discussion.votesCount > 0
                        ? AppColors.forestGreen
                        : _discussion.votesCount < 0
                            ? AppColors.deepRed
                            : _kTextSecondary,
                  ),
                ),
                const Spacer(),
                if (_isAuthenticated) ...[
                  _VoteButton(
                    icon: Icons.thumb_up_outlined,
                    activeIcon: Icons.thumb_up,
                    isActive: _userVote == 1,
                    activeColor: AppColors.forestGreen,
                    onTap: _votingInProgress ? null : () => _vote(1),
                  ),
                  const SizedBox(width: 4),
                  _VoteButton(
                    icon: Icons.thumb_down_outlined,
                    activeIcon: Icons.thumb_down,
                    isActive: _userVote == -1,
                    activeColor: AppColors.deepRed,
                    onTap: _votingInProgress ? null : () => _vote(-1),
                  ),
                ],
              ],
            ),
          ),

          // ── Author actions ───────────────────────────────────────────────
          if (_isAuthor) ...[
            const Divider(height: 1, color: _kDivider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_nextStage(_discussion.stage) != null)
                    OutlinedButton.icon(
                      onPressed: _advancingStage ? null : _advanceStage,
                      icon: _advancingStage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brightCyan),
                            )
                          : const Icon(Icons.arrow_forward,
                              size: 16, color: AppColors.brightCyan),
                      label: Text(
                        'Advance to ${_nextStage(_discussion.stage)!.label}',
                        style:
                            const TextStyle(color: AppColors.brightCyan),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.brightCyan.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (_discussion.stage ==
                      DiscussionStage.projectProposal) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _launchProjectFlow,
                      icon: const Icon(Icons.rocket_launch_outlined,
                          size: 16),
                      label: const Text('Create Project from This'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stage stepper ─────────────────────────────────────────────────────────────

class _StageStepper extends StatelessWidget {
  final DiscussionStage currentStage;

  const _StageStepper({required this.currentStage});

  static const _stages = DiscussionStage.values;

  @override
  Widget build(BuildContext context) {
    final currentIndex =
        _stages.indexWhere((s) => s.value == currentStage.value);

    return Row(
      children: List.generate(_stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stageIndex = i ~/ 2;
          final isCompleted = stageIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.electricBlue : _kBorder,
            ),
          );
        }
        // Stage node
        final stageIndex = i ~/ 2;
        final stage = _stages[stageIndex];
        final isCompleted = stageIndex < currentIndex;
        final isCurrent = stageIndex == currentIndex;

        return _StageNode(
          stage: stage,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
        );
      }),
    );
  }
}

class _StageNode extends StatelessWidget {
  final DiscussionStage stage;
  final bool isCompleted;
  final bool isCurrent;

  const _StageNode({
    required this.stage,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted || isCurrent
        ? AppColors.electricBlue
        : _kBorder;
    final emoji = stage.label.split(' ').first;

    return Tooltip(
      message: '${stage.label}\n${stage.description}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.electricBlue
                  : isCurrent
                      ? AppColors.electricBlue.withOpacity(0.2)
                      : _kInputFill,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check,
                      size: 16, color: AppColors.white)
                  : Text(emoji,
                      style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _shortLabel(stage),
            style: TextStyle(
              fontSize: 9,
              fontWeight:
                  isCurrent ? FontWeight.w700 : FontWeight.normal,
              color:
                  isCurrent ? AppColors.brightCyan : _kTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _shortLabel(DiscussionStage stage) {
    switch (stage) {
      case DiscussionStage.problem:
        return 'Problem';
      case DiscussionStage.solution:
        return 'Solution';
      case DiscussionStage.projectProposal:
        return 'Proposal';
      case DiscussionStage.projectLinked:
        return 'Project';
    }
  }
}

// ── Stage pill ────────────────────────────────────────────────────────────────

class _StagePill extends StatelessWidget {
  final DiscussionStage stage;

  const _StagePill({required this.stage});

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        stage.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _stageColor(DiscussionStage stage) {
    switch (stage) {
      case DiscussionStage.problem:
        return AppColors.deepRed;
      case DiscussionStage.solution:
        return AppColors.warmAmber;
      case DiscussionStage.projectProposal:
        return AppColors.electricBlue;
      case DiscussionStage.projectLinked:
        return AppColors.forestGreen;
    }
  }
}

// ── Vote button ───────────────────────────────────────────────────────────────

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 22,
          color: isActive ? activeColor : _kTextSecondary,
        ),
      ),
    );
  }
}


/// Standalone stage badge widget — used in feed cards and other list views.
class PipelineStageBadge extends StatelessWidget {
  final DiscussionStage stage;
  final double fontSize;

  const PipelineStageBadge({
    super.key,
    required this.stage,
    this.fontSize = 10,
  });

  Color _color() {
    switch (stage) {
      case DiscussionStage.problem:
        return AppColors.deepRed;
      case DiscussionStage.solution:
        return AppColors.warmAmber;
      case DiscussionStage.projectProposal:
        return AppColors.electricBlue;
      case DiscussionStage.projectLinked:
        return AppColors.forestGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        stage.label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
