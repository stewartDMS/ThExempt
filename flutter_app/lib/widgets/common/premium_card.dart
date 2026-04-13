import 'package:flutter/material.dart';

/// A premium card wrapper with hover animations and gradient shadow.
/// Wraps any [child] in an elevated, rounded container with smooth hover effects.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final Color? accentColor;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  /// Card surface color. Defaults to [Colors.white].
  final Color? backgroundColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.accentColor,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? Colors.grey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: widget.backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(_isHovered ? 0.15 : 0.08),
            blurRadius: _isHovered ? 20 : 12,
            offset: Offset(0, _isHovered ? 8 : 4),
            spreadRadius: _isHovered ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          // onHover fires on desktop/web where hover is available.
          // On mobile, InkWell's built-in ink splash provides press feedback.
          onHover: (hovering) => setState(() => _isHovered = hovering),
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.padding != null
                ? Padding(padding: widget.padding!, child: widget.child)
                : widget.child,
          ),
        ),
      ),
    );
  }
}
