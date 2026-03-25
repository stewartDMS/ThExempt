import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../theme/app_colors.dart';
import 'category_discussions_screen.dart';

/// Displays all discussion categories in a clean list – moved here from
/// CommunityHubScreen so the hub can focus on the discussion feed.
class DiscussionCategoriesScreen extends StatelessWidget {
  const DiscussionCategoriesScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Categories')),
      backgroundColor: AppColors.scaffoldBackground,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: DiscussionCategory.values.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cat = DiscussionCategory.values[index];
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
    );
  }
}
