import 'package:flutter/material.dart';
import '../models/project_model.dart';
import 'discovery_project_card.dart';

/// Shows the top-matching projects for the current user at the top of the
/// Discovery screen.
class BestMatchesSection extends StatelessWidget {
  final List<({Project project, int matchScore, List<String> openRoleTitles})>
      matches;

  const BestMatchesSection({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Best Matches For You',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        ...matches.take(5).map(
              (m) => DiscoveryProjectCard(
                project: m.project,
                matchScore: m.matchScore,
                openRoleTitles: m.openRoleTitles,
              ),
            ),
        const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'All Projects',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
