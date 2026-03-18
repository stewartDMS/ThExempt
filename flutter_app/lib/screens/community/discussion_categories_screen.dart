import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../theme/app_colors.dart';
import 'category_discussions_screen.dart';

/// Displays all discussion categories in a clean list – moved here from
/// CommunityHubScreen so the hub can focus on the discussion feed.
class DiscussionCategoriesScreen extends StatelessWidget {
  const DiscussionCategoriesScreen({super.key});

  static const _categoryColors = {
    'world_problems': Color(0xFF057642),
    'ideas': Color(0xFFF5A623),
    'learning': Color(0xFF0A66C2),
    'live_events': Color(0xFFCC1016),
    'networking': Color(0xFF7B61FF),
    'feedback': Color(0xFFE91E8C),
    'general': Color(0xFF666666),
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
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
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
