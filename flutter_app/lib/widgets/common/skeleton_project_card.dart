import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'shimmer_widget.dart';

/// Skeleton placeholder that mirrors the layout of a [ProjectCard],
/// shown while project data is being fetched.
class SkeletonProjectCard extends StatelessWidget {
  const SkeletonProjectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name
          Row(
            children: [
              ShimmerWidget(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ShimmerWidget(
                      width: 80,
                      height: 12,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Video thumbnail
          ShimmerWidget(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          ShimmerWidget(
            width: 200,
            height: 20,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Description lines
          ShimmerWidget(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: AppSpacing.xs),
          ShimmerWidget(
            width: 260,
            height: 14,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tag pills
          Row(
            children: [
              ShimmerWidget(
                width: 80,
                height: 28,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShimmerWidget(
                width: 80,
                height: 28,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShimmerWidget(
                width: 80,
                height: 28,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
