import 'package:flutter/material.dart';
import '../../models/discussion_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'category_discussions_screen.dart';

const _kBg            = Color(0xFF14141A);
const _kCardBg        = Color(0xFF1C1C1E);
const _kBorder        = Color(0xFF3A3A3C);
const _kDivider       = Color(0xFF2C2C2F);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class DiscussionCategoriesScreen extends StatefulWidget {
  const DiscussionCategoriesScreen({super.key});

  @override
  State<DiscussionCategoriesScreen> createState() =>
      _DiscussionCategoriesScreenState();
}

class _DiscussionCategoriesScreenState
    extends State<DiscussionCategoriesScreen> {
  String _filter = 'all';

  static const _categoryColors = {
    'world_problems':       Color(0xFF057642),
    'ideas':                Color(0xFFF5A623),
    'learning':             Color(0xFF0A66C2),
    'live_events':          Color(0xFFCC1016),
    'networking':           Color(0xFF7B61FF),
    'feedback':             Color(0xFFE91E8C),
    'general':              Color(0xFF666666),
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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Browse Categories',
          style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kTextSecondary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildFilterRow(categories),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _kDivider),
        itemBuilder: (context, index) {
          final cat   = categories[index];
          final color = _categoryColors[cat.value] ?? const Color(0xFF666666);
          final parts = cat.label.split(' ');
          final emoji = parts.isNotEmpty ? parts[0] : '';
          final name  = parts.length > 1
              ? parts.sublist(1).join(' ')
              : cat.label;

          return _CategoryRow(
            emoji: emoji,
            name: name,
            description: cat.description,
            isSystemic: cat.isSystemic,
            color: color,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CategoryDiscussionsScreen(category: cat.value),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(List<DiscussionCategory> categories) {
    final all      = DiscussionCategory.values.length;
    final systemic = DiscussionCategory.values.where((c) => c.isSystemic).length;
    final general  = all - systemic;

    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
                label: 'All ($all)',
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all')),
            const SizedBox(width: 8),
            _FilterChip(
                label: '🔴 Systemic ($systemic)',
                selected: _filter == 'systemic',
                onTap: () => setState(() => _filter = 'systemic')),
            const SizedBox(width: 8),
            _FilterChip(
                label: '💬 General ($general)',
                selected: _filter == 'general',
                onTap: () => setState(() => _filter = 'general')),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.electricBlue.withOpacity(0.2)
              : _kCardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? AppColors.brightCyan.withOpacity(0.6)
                : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.brightCyan : _kTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Category row ───────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;
  final bool isSystemic;
  final Color color;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.emoji,
    required this.name,
    required this.description,
    required this.isSystemic,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: _kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary,
                          ),
                        ),
                      ),
                      if (isSystemic) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: color.withOpacity(0.35), width: 1),
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
                    description,
                    style: const TextStyle(
                        fontSize: 12, color: _kTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: _kTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
