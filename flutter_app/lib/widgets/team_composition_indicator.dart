import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Visual indicator showing team composition (filled vs open roles).
/// Uses coloured dots and an emoji status to communicate fullness at a glance.
class TeamCompositionIndicator extends StatelessWidget {
  final int totalRoles;
  final int filledRoles;

  const TeamCompositionIndicator({
    super.key,
    required this.totalRoles,
    required this.filledRoles,
  });

  @override
  Widget build(BuildContext context) {
    if (totalRoles == 0) return const SizedBox.shrink();

    final int openRoles = totalRoles - filledRoles;
    final double fillRatio =
        totalRoles > 0 ? filledRoles / totalRoles : 0.0;

    String emoji;
    String label;
    Color labelColor;

    if (fillRatio >= 1.0) {
      emoji = '✅';
      label = 'Team full';
      labelColor = Colors.green[700]!;
    } else if (fillRatio >= 0.5) {
      emoji = '🟡';
      label = '$openRoles spot${openRoles == 1 ? '' : 's'} left';
      labelColor = AppColors.warmAmber;
    } else {
      emoji = '❌';
      label = '$openRoles open role${openRoles == 1 ? '' : 's'} needed';
      labelColor = Colors.red[600]!;
    }

    return Row(
      children: [
        // Dot progress bar – cap at 10 dots to avoid overflow on large teams
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalRoles.clamp(0, 10), (i) {
              final filled = i < filledRoles;
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? Colors.green[500] : Colors.grey[300],
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
