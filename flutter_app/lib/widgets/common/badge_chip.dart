import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A colored chip used for tags, categories, and badges
class BadgeChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double fontSize;
  final bool outlined;

  const BadgeChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.fontSize = 12,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveTextColor = outlined
        ? effectiveColor
        : (textColor ?? AppColors.white);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : effectiveColor.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: outlined
            ? Border.all(color: effectiveColor.withAlpha(150), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: outlined ? effectiveColor : effectiveTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
