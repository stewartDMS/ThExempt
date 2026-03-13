import 'package:flutter/material.dart';
import '../../models/project_stage.dart';
import '../../theme/app_colors.dart';

class StageBadge extends StatelessWidget {
  final ProjectStage stage;
  final bool showDescription;
  final bool compact;

  const StageBadge({
    super.key,
    required this.stage,
    this.showDescription = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: stage.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: stage.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stage.emoji,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              stage.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: stage.color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stage.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stage.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                stage.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                '${stage.displayName} Stage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: stage.color,
                ),
              ),
            ],
          ),
          if (showDescription) ...[
            const SizedBox(height: 4),
            Text(
              stage.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
