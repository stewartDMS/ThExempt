import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Skeleton/shimmer loading placeholder
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusSm,
  });

  /// Convenience constructor for a skeleton card
  const SkeletonLoader.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.grey200.withAlpha((_animation.value * 255).round()),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// A pre-built skeleton card that mimics a project card
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(width: 48, height: 48, borderRadius: AppSpacing.radiusMd),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 120, height: 14),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonLoader(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SkeletonLoader(height: 180),
          SizedBox(height: AppSpacing.md),
          SkeletonLoader(height: 20, width: 200),
          SizedBox(height: AppSpacing.sm),
          SkeletonLoader(height: 14),
          SizedBox(height: AppSpacing.xs),
          SkeletonLoader(height: 14, width: 260),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SkeletonLoader(width: 80, height: 28, borderRadius: AppSpacing.radiusFull),
              SizedBox(width: AppSpacing.sm),
              SkeletonLoader(width: 80, height: 28, borderRadius: AppSpacing.radiusFull),
              SizedBox(width: AppSpacing.sm),
              SkeletonLoader(width: 80, height: 28, borderRadius: AppSpacing.radiusFull),
            ],
          ),
        ],
      ),
    );
  }
}
