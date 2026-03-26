import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../theme/app_colors.dart';
import 'category_discussions_screen.dart';

/// Displays all discussion categories in a clean list – moved here from
/// CommunityHubScreen so the hub can focus on the discussion feed.
/// Now a StatefulWidget to support filtering between All and Systemic categories.
class DiscussionCategoriesScreen extends StatefulWidget {
  const DiscussionCategoriesScreen({super.key});

  @override
  State<DiscussionCategoriesScreen> createState() =>
      _DiscussionCategoriesScreenState();
}

class _DiscussionCategoriesScreenState
    extends State<DiscussionCategoriesScreen> {
  // Filter: 'all' | 'systemic' | 'general'
  String _filter = 'all';

  static const _categoryColors = {
    // Original categories
    'world_problems':       Color(0xFF057642),
    'ideas':                Color(0xFFF5A623),
    'learning':             Color(0xFF0A66C2),
    'live_events':          Color(0xFFCC1016),
    'networking':           Color(0xFF7B61FF),
    'feedback':             Color(0xFFE91E8C),
    'general':              Color(0xFF666666),
    // Phase 1 systemic categories
    'democracy':            Color(0xFF1565C0),
    'climate_crisis':       Color(0xFFE53935),
    'economic_inequality':  Color(0xFFFB8C00),
    'healthcare_access':    Color(0xFFE91E63),
    'education_reform':     Color(0xFF3F51B5),
    'housing_justice':      Color(0xFF009688),
    'criminal_justice':     Color(0xFF795548),
    'immigration_justice':  Color(0xFF607D8B),
    'mental_health_crisis': Color(0xFF9C27B0),
    'community_building':   Color(0xFF43A047),
    'technology':           Color(0xFF00ACC1),
  };

  List<DiscussionCategory> get _filteredCategories {
    switch (_filter) {
      case 'systemic':
        return DiscussionCategory.values.where((c) => c.isSystemic).toList();
      case 'general':
        return DiscussionCategory.values.where((c) => !c.isSystemic).toList();
      default:
        return DiscussionCategory.values;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Categories')),
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${DiscussionCategory.values.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'systemic',
                    '🔴 Systemic Change (${DiscussionCategory.values.where((c) => c.isSystemic).length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'general',
                    '💬 General (${DiscussionCategory.values.where((c) => !c.isSystemic).length})',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // ── Category list ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final color =
                    _categoryColors[cat.value] ?? const Color(0xFF666666);
                final parts = cat.label.split(' ');
                final emoji = parts.isNotEmpty ? parts[0] : '';
                final name = parts.length > 1
                    ? parts.sublist(1).join(' ')
                    : cat.label;

                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CategoryDiscussionsScreen(category: cat.value),
                    ),
                  ),
                  child: Container(
                    color: AppColors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey900,
                                      ),
                                    ),
                                  ),
                                  if (cat.isSystemic) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(25),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: color.withAlpha(80), width: 1),
                                      ),
                                      child: Text(
                                        'Systemic',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cat.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.grey400, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}
