import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Animated shimmer widget that displays a sweeping gradient highlight,
/// used as the base building block for skeleton loaders.
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      builder: (context, _) {
        // Bright spot sweeps from left (-1) to right (2) as t goes 0→1
        final double shimmerPos = -1.0 + _animation.value * 3.0;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusSm),
            gradient: LinearGradient(
              begin: Alignment(shimmerPos - 1, 0),
              end: Alignment(shimmerPos + 1, 0),
              colors: const [
                AppColors.grey200,
                AppColors.grey100,
                AppColors.grey200,
              ],
            ),
          ),
        );
      },
    );
  }
}
