import 'package:flutter/material.dart';

/// Horizontal scrollable filter chips for role categories.
class RoleCategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  static const List<Map<String, dynamic>> categories = [
    {'label': 'All', 'value': null, 'icon': Icons.apps},
    {'label': 'Technical', 'value': 'Technical', 'icon': Icons.code},
    {'label': 'Business', 'value': 'Business', 'icon': Icons.business_center},
    {'label': 'Marketing', 'value': 'Marketing', 'icon': Icons.campaign},
    {'label': 'Design', 'value': 'Design', 'icon': Icons.brush},
    {'label': 'Finance', 'value': 'Finance', 'icon': Icons.attach_money},
    {'label': 'Operations', 'value': 'Operations', 'icon': Icons.settings},
    {'label': 'Legal', 'value': 'Legal', 'icon': Icons.gavel},
    {'label': 'Other', 'value': 'Other', 'icon': Icons.more_horiz},
  ];

  const RoleCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final String? value = cat['value'] as String?;
          final bool isSelected = selectedCategory == value;

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 14,
                  color: isSelected ? Colors.white : colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(cat['label'] as String),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onCategoryChanged(value),
            selectedColor: colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: colorScheme.primary.withOpacity(0.08),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.primary.withOpacity(0.3),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          );
        },
      ),
    );
  }
}
