import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A collapsible container that wraps filter controls.
///
/// Shows a "Filters ▼" header that the user can tap to expand / collapse.
class FilterPanel extends StatefulWidget {
  final Widget child;
  final bool initiallyExpanded;

  const FilterPanel({
    super.key,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.tune,
                      size: 18, color: AppColors.grey700),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.grey500,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppColors.grey200),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
