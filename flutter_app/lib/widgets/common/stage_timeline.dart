import 'package:flutter/material.dart';
import '../../models/project_stage.dart';
import '../../theme/app_colors.dart';

class StageTimeline extends StatelessWidget {
  final ProjectStage currentStage;

  const StageTimeline({
    super.key,
    required this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    final stages = ProjectStage.values;
    final currentIndex = stages.indexOf(currentStage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Timeline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(stages.length * 2 - 1, (index) {
              if (index.isEven) {
                // Stage dot
                final stageIndex = index ~/ 2;
                final stage = stages[stageIndex];
                final isCompleted = stageIndex < currentIndex;
                final isCurrent = stageIndex == currentIndex;

                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? stage.color
                            : AppColors.grey300,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: stage.color,
                                width: 3,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                stage.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        stage.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted || isCurrent
                              ? stage.color
                              : AppColors.grey400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              } else {
                // Connector line
                final stageIndex = index ~/ 2;
                final isCompleted = stageIndex < currentIndex;

                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    color: isCompleted
                        ? stages[stageIndex].color
                        : AppColors.grey300,
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}
