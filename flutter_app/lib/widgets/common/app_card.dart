import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Standard app card container with consistent shadow, border radius, and
/// optional tap handler.  Use this as the root widget for project and
/// discussion cards to ensure a unified look across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Inner padding applied around [child].  Defaults to no padding so that
  /// callers can compose [Padding] themselves when they need different insets
  /// for different sections (e.g. a full-bleed image followed by padded text).
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}

/// Reusable card header that renders an avatar, name/subtitle column,
/// an optional badge (e.g. [StageBadge] or a category pill), and an
/// optional trailing widget (e.g. a [PopupMenuButton] or bookmark icon).
///
/// Both [ProjectCard] and [DiscussionFeedCard] use this to guarantee a
/// consistent header layout across the app.
class CardHeader extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String subtitle;

  /// Shown between the name/subtitle column and [trailing].
  final Widget? badge;

  /// Shown at the far right of the header (e.g. three-dot menu or bookmark).
  final Widget? trailing;

  /// Called when the avatar is tapped.
  final VoidCallback? onAvatarTap;

  /// Called when the name text is tapped.
  final VoidCallback? onNameTap;

  const CardHeader({
    super.key,
    this.avatarUrl,
    required this.name,
    required this.subtitle,
    this.badge,
    this.trailing,
    this.onAvatarTap,
    this.onNameTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Avatar ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: onAvatarTap,
          child: avatarUrl != null
              ? CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatarUrl!),
                  onBackgroundImageError: (_, __) {},
                )
              : CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        // ── Name + subtitle ─────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onNameTap,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
        // ── Badge ───────────────────────────────────────────────────────
        if (badge != null) ...[
          badge!,
          const SizedBox(width: 8),
        ],
        // ── Trailing action ─────────────────────────────────────────────
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Consistent pill chip used to display skills, tags, and similar short
/// labels on project and discussion cards.
class SkillChip extends StatelessWidget {
  final String label;

  /// Text color. Defaults to [AppColors.primary].
  final Color? color;

  /// Background color. Defaults to [AppColors.primaryContainer].
  final Color? backgroundColor;

  const SkillChip({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
