import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A single item in a [FilterDropdown].
class DropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? emoji;
  final Color? color;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.emoji,
    this.color,
  });
}

/// A labelled dropdown wrapper that prevents horizontal overflow.
///
/// Replaces horizontally-scrolling filter chip rows on all screens.
class FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.grey200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.grey500, size: 20),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Row(
                    children: [
                      if (item.emoji != null) ...[
                        Text(item.emoji!,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: AppSpacing.sm),
                      ] else if (item.icon != null) ...[
                        Icon(item.icon,
                            size: 16,
                            color: item.color ?? AppColors.grey600),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
