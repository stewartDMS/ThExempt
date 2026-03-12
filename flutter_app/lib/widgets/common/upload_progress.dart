import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Circular progress indicator for upload operations.
///
/// Shows a percentage label inside the circular indicator and an optional
/// text label above it.
class UploadProgress extends StatelessWidget {
  /// Upload progress between 0.0 and 1.0.
  final double progress;

  /// Optional descriptive label shown above the indicator.
  final String? label;

  const UploadProgress({
    super.key,
    required this.progress,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: AppColors.grey200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.grey800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
