import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A consistently-styled card with optional tap, elevation, and border
class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool hasBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd);
    final effectiveElevation = elevation ?? AppSpacing.elevationSm;

    return Card(
      margin: margin ?? EdgeInsets.zero,
      elevation: effectiveElevation,
      shadowColor: AppColors.grey300,
      surfaceTintColor: Colors.transparent,
      color: color ?? AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveRadius,
        side: hasBorder
            ? const BorderSide(color: AppColors.grey200)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
