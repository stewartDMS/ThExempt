import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'shimmer_widget.dart';

/// Skeleton placeholder that mirrors the layout of a [DiscussionFeedCard],
/// shown while discussion data is being fetched.
class SkeletonDiscussionCard extends StatelessWidget {
  const SkeletonDiscussionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              ShimmerWidget(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    width: 120,
                    height: 12,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ShimmerWidget(
                    width: 70,
                    height: 10,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Category badge
          ShimmerWidget(
            width: 80,
            height: 20,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          ShimmerWidget(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Description lines
          ShimmerWidget(
            width: double.infinity,
            height: 13,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: AppSpacing.xs),
          ShimmerWidget(
            width: 200,
            height: 13,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: AppSpacing.md),

          // Engagement row
          Row(
            children: [
              ShimmerWidget(
                width: 50,
                height: 12,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              const SizedBox(width: AppSpacing.lg),
              ShimmerWidget(
                width: 50,
                height: 12,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
