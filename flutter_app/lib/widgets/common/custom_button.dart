import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/text_styles.dart';

/// Button variants
enum ButtonVariant { primary, secondary, outlined, text, danger }

/// Reusable button with gradient support for primary variant
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double? height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == ButtonVariant.primary) {
      return _GradientButton(
        label: label,
        onPressed: isLoading ? null : onPressed,
        isLoading: isLoading,
        fullWidth: fullWidth,
        icon: icon,
        height: height ?? AppSpacing.minTouchTarget,
      );
    }

    if (variant == ButtonVariant.outlined) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height ?? AppSpacing.minTouchTarget,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(),
        ),
      );
    }

    if (variant == ButtonVariant.text) {
      return SizedBox(
        height: height ?? AppSpacing.minTouchTarget,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(),
        ),
      );
    }

    if (variant == ButtonVariant.danger) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height ?? AppSpacing.minTouchTarget,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: _buildChild(),
        ),
      );
    }

    // secondary
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? AppSpacing.minTouchTarget,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.button),
        ],
      );
    }
    return Text(label, style: AppTextStyles.button);
  }
}

/// Gradient-filled primary button
class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double height;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.fullWidth,
    required this.height,
    this.icon,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.6 : 1.0,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : widget.icon != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon,
                                size: AppSpacing.iconMd,
                                color: AppColors.white),
                            const SizedBox(width: AppSpacing.sm),
                            Text(widget.label,
                                style: AppTextStyles.button
                                    .copyWith(color: AppColors.white)),
                          ],
                        )
                      : Text(
                          widget.label,
                          style: AppTextStyles.button
                              .copyWith(color: AppColors.white),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
