import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

// Dark palette
const _kInputFill = Color(0xFF252528);
const _kBorder = Color(0xFF3A3A3C);
const _kTextPrimary = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class SkillsInputWidget extends StatefulWidget {
  final List<String> selectedSkills;
  final Function(List<String>) onSkillsChanged;

  const SkillsInputWidget({
    super.key,
    required this.selectedSkills,
    required this.onSkillsChanged,
  });

  @override
  State<SkillsInputWidget> createState() => _SkillsInputWidgetState();
}

class _SkillsInputWidgetState extends State<SkillsInputWidget> {
  final TextEditingController _skillController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _suggestedSkills = [
    'React', 'Flutter', 'Node.js', 'Python', 'JavaScript',
    'TypeScript', 'Java', 'C++', 'Swift', 'Kotlin',
    'Go', 'Rust', 'PHP', 'Ruby', 'SQL',
    'MongoDB', 'PostgreSQL', 'Firebase', 'AWS', 'Docker',
    'Kubernetes', 'GraphQL', 'REST API', 'UI/UX Design', 'Figma',
  ];

  @override
  void dispose() {
    _skillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isNotEmpty && !widget.selectedSkills.contains(trimmed)) {
      widget.onSkillsChanged(
          List<String>.from(widget.selectedSkills)..add(trimmed));
      _skillController.clear();
    }
  }

  void _removeSkill(String skill) {
    widget.onSkillsChanged(
        List<String>.from(widget.selectedSkills)..remove(skill));
  }

  @override
  Widget build(BuildContext context) {
    final available = _suggestedSkills
        .where((s) => !widget.selectedSkills.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input row ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                focusNode: _focusNode,
                style: const TextStyle(color: _kTextPrimary, fontSize: 14),
                onSubmitted: (v) {
                  _addSkill(v);
                  _focusNode.requestFocus();
                },
                decoration: InputDecoration(
                  hintText: 'Add a skill and press Enter…',
                  hintStyle: TextStyle(
                      color: _kTextSecondary.withOpacity(0.5), fontSize: 13),
                  prefixIcon: const Icon(Icons.add_circle_outline,
                      color: _kTextSecondary, size: 20),
                  filled: true,
                  fillColor: _kInputFill,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                        color: AppColors.brightCyan, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _GradientIconButton(
              icon: Icons.add_rounded,
              onPressed: () => _addSkill(_skillController.text),
            ),
          ],
        ),

        // ── Selected chips ─────────────────────────────────────────
        if (widget.selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selectedSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: AppColors.electricBlue.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brightCyan,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeSkill(skill),
                      child: const Icon(Icons.close,
                          size: 14, color: AppColors.brightCyan),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],

        // ── Suggestions ────────────────────────────────────────────
        if (available.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Quick add:',
            style: TextStyle(
                fontSize: 11,
                color: _kTextSecondary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: available.take(10).map((skill) {
              return GestureDetector(
                onTap: () => _addSkill(skill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kInputFill,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add,
                          size: 12, color: _kTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        skill,
                        style: const TextStyle(
                            fontSize: 11, color: _kTextSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Small icon-only gradient button.
class _GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GradientIconButton(
      {required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
