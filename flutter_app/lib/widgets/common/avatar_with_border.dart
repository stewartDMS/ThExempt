import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Circular avatar with a colored border and optional badge
class AvatarWithBorder extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const AvatarWithBorder({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 28,
    this.borderColor,
    this.borderWidth = 2.5,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? Theme.of(context).colorScheme.primary.withAlpha(51);
    final effectiveBg = backgroundColor ?? AppColors.primary;
    final display = initials?.isNotEmpty == true ? initials![0].toUpperCase() : '?';

    return Container(
      width: (radius + borderWidth) * 2,
      height: (radius + borderWidth) * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withAlpha(128),
            blurRadius: AppSpacing.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(effectiveBg, display, radius),
              )
            : _placeholder(effectiveBg, display, radius),
      ),
    );
  }

  Widget _placeholder(Color bg, String letter, double r) {
    return Container(
      width: r * 2,
      height: r * 2,
      color: bg,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: r * 0.75,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
